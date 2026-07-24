# infra/terraform

現在稼働中のAWS構成（EC2単体版、`../ec2/`のJSONで記録していたもの）をコード化したもの。VPC/サブネット/IGW/ルートテーブル/セキュリティグループ/EC2/ALB/ターゲットグループ/リスナー/ACM証明書/Route53レコード/ECRリポジトリまでを管理します。

State はローカル管理です（S3バックエンド等は未導入）。個人ポートフォリオ規模のため、追加のAWSリソース（S3+DynamoDB）を常時稼働させるコストを避けています。

Fargate + RDS構成（`../fargate/`）は現在停止中のため、このTerraformの対象外です。

## セットアップ

```bash
cd infra/terraform
cp terraform.tfvars.example terraform.tfvars
# terraform.tfvars を編集し、admin_ssh_cidr / budget_alert_email を自分の値に設定
terraform init
```

## デプロイ（新規環境）

新しいAWSアカウント／リージョンに一から構築する場合は、通常の`apply`で完結します。

```bash
terraform plan
terraform apply
```

VPCからEC2・ALB・Route53レコードまで、このコードだけで再現できます。

## 既存stateとの再接続（このAWSアカウントに対して行う場合）

このリポジトリのstateはローカルにしかないため、別のマシンからこの既にデプロイ済みのAWSアカウント（743334887511）に対して作業する場合は、`apply`で作り直すのではなく`import`で既存リソースをstateに取り込んでください。`import`はAWS側を一切変更しません（stateに記録するだけです）。

```bash
terraform import aws_vpc.main vpc-046bbaf9d6d4ff8c3
terraform import aws_internet_gateway.main igw-0a765782c4efcefff
terraform import aws_subnet.public_1a subnet-08f1f08a9880d4529
terraform import aws_subnet.public_1c subnet-019d286505ef84f91
terraform import aws_subnet.private_1a subnet-00fbe1c85a47766f3
terraform import aws_subnet.private_1c subnet-0a675867c645931a0
terraform import aws_route_table.public rtb-03ac75679e061b8d3
terraform import aws_route_table.private rtb-07360b083660c1fcb
terraform import aws_route_table_association.public_1a subnet-08f1f08a9880d4529/rtb-03ac75679e061b8d3
terraform import aws_route_table_association.public_1c subnet-019d286505ef84f91/rtb-03ac75679e061b8d3
terraform import aws_route_table_association.private_1a subnet-00fbe1c85a47766f3/rtb-07360b083660c1fcb
terraform import aws_route_table_association.private_1c subnet-0a675867c645931a0/rtb-07360b083660c1fcb
terraform import aws_security_group.alb sg-0cd3ad5922f1bb4b2
terraform import aws_security_group.ec2 sg-049eab087d597371f
terraform import aws_instance.app i-00f1842abeaac406f
terraform import aws_lb.main arn:aws:elasticloadbalancing:ap-northeast-1:743334887511:loadbalancer/app/myapp-alb/7165ca8f183ff38d
terraform import aws_lb_target_group.backend arn:aws:elasticloadbalancing:ap-northeast-1:743334887511:targetgroup/myapp-ec2-backend-tg/390cbad157e40dcc
terraform import aws_lb_target_group.frontend arn:aws:elasticloadbalancing:ap-northeast-1:743334887511:targetgroup/myapp-ec2-frontend-tg/3a6828b8cbb1a7bc
terraform import aws_lb_listener.http arn:aws:elasticloadbalancing:ap-northeast-1:743334887511:listener/app/myapp-alb/7165ca8f183ff38d/2417d4ad9518b0d0
terraform import aws_lb_listener.https arn:aws:elasticloadbalancing:ap-northeast-1:743334887511:listener/app/myapp-alb/7165ca8f183ff38d/ad6f41529d112ac9
terraform import aws_lb_listener_rule.api_to_backend arn:aws:elasticloadbalancing:ap-northeast-1:743334887511:listener-rule/app/myapp-alb/7165ca8f183ff38d/ad6f41529d112ac9/574b7ac26a142036
terraform import aws_acm_certificate.main arn:aws:acm:ap-northeast-1:743334887511:certificate/86081b1a-0dac-4438-b449-9a8274cef6e4
terraform import aws_route53_record.app_a Z05506923OMK303C1PA83_myapp.imauty.com_A
terraform import aws_route53_record.app_aaaa Z05506923OMK303C1PA83_myapp.imauty.com_AAAA
terraform import aws_route53_record.cert_validation Z05506923OMK303C1PA83__296c60637e52ff1f9756a1dffb04eb5b.myapp.imauty.com_CNAME
terraform import aws_ecr_repository.backend myapp-backend
terraform import aws_ecr_repository.frontend myapp-frontend
terraform import aws_budgets_budget.monthly 743334887511:myapp-monthly-budget
```

`aws_lb_target_group_attachment`はTerraformの仕様上importに対応していません。import後の`terraform plan`で2件（backend/frontend）が「追加」として出ますが、これは既存の登録をterraformの管理下に置くだけの安全な操作なので、そのまま`apply`してください。

## plan/apply共通の注意

```bash
terraform plan
```

を実行し、意図しない差分がないか必ず確認してから`apply`してください。ここは本番稼働中のポートフォリオサイトを載せているインスタンスなので、意図しない`apply`はサービス停止やデータ消失（DBもこのEC2上にあるため）につながります。

## コスト監視

`aws_budgets_budget.monthly`（`budget.tf`）で月$50の予算に対し、実績50%/80%・予測100%の3段階でメール通知します。Cost Explorer / Budgets APIは実際のリソースのリージョン（ap-northeast-1）に関わらず`us-east-1`でのみ提供されているため、`provider.aws.billing`エイリアスで明示的にus-east-1を指定しています。

現在の内訳を手元で確認したい場合は以下を実行してください。

```bash
../scripts/cost-report.sh
```

## IAM（デプロイユーザーの権限）

`myapp-deploy`ユーザーは元々`AdministratorAccess`が付いていましたが、`iam.tf`で以下の最小権限セットに絞っています（`data "aws_iam_user"`でユーザー自体を参照するのみで、ユーザーの作成・削除はTerraformの管理外です）。

- `AmazonEC2FullAccess` / `ElasticLoadBalancingFullAccess` / `AmazonRoute53FullAccess` / `AWSCertificateManagerFullAccess` / `AmazonEC2ContainerRegistryFullAccess`（AWS管理ポリシー）
- `myapp-deploy-billing`（カスタムポリシー）: Budgets（`ViewBudget`/`ModifyBudget`/タグ関連）とCost Explorer・Free Tierの読み取り
- `myapp-deploy-iam-bootstrap`（カスタムポリシー）: `myapp-deploy`が自分自身のポリシーアタッチと、`myapp-deploy-billing`／このポリシー自身のバージョン管理を行えるようにする、自己管理用の権限

`myapp-deploy-iam-bootstrap`は最終的に全てTerraformで管理する形に落ち着きました。ポイントは以下の2つです。

- `iam:AttachUserPolicy` / `iam:DetachUserPolicy`は自分自身に対してのみ、かつ上記7ポリシーARN（自分自身含む）以外はアタッチできないよう`Condition`で制限しています。`AdministratorAccess`を自分に付け直すような権限昇格はできません。
- `aws_iam_policy`リソースの`description`は設定していません。IAMポリシーの`description`はTerraform上「変更すると作り直し（destroy→create）が必要な属性」であり、このポリシー自身を作り直すと自己管理権限が一瞬失われ、以後のapplyが失敗する可能性があるためです。今後このリソースを編集する際は、作り直し（`must be replaced`）が発生する変更でないか`terraform plan`で必ず確認してください。

### Permissions Boundary

上記の通り`myapp-deploy`は`myapp-deploy-iam-bootstrap`ポリシー自体を書き換えられるため、理論上は自分自身のガード条件を書き換えて再エスカレーションする経路が残っていました。これを塞ぐため、`myapp-deploy`ユーザーに**Permissions Boundary**（`myapp-deploy-boundary`）を設定しています。

Permissions Boundaryは「このユーザーのIDベースポリシーがどうであれ、実効権限はこの範囲を超えられない」という上限を課す仕組みです。効果は「IDベースポリシーの許可」と「Boundaryの許可」の**両方に含まれる権限のみが実際に有効になる**、という交差(AND)で決まります。

**このBoundaryポリシー自体は、意図的にTerraformの管理対象にしていません（唯一の例外）。** 理由は構造的なもので、Boundaryは「本人が変更できないこと」が存在意義そのものだからです。`myapp-deploy`にBoundaryの内容を読み書きする権限を与えてしまうと、Boundaryを設定した意味がなくなります。実際、`myapp-deploy-boundary`の中には`iam:PutUserPermissionsBoundary` / `iam:DeleteUserPermissionsBoundary`への明示的Deny（`Effect: Deny`は他のどのAllowよりも優先される）が入っており、`myapp-deploy`自身は自分のBoundaryを変更・解除できません。設定・変更は必ずAWSコンソールからルート/別の管理者権限で行う必要があります。

動作確認済みの内容:
- `myapp-deploy`の通常運用（EC2/ALB/Route53/ACM/ECR/Budgets/Cost Explorer、Terraformでの自己ポリシー管理）は影響を受けない
- `iam:CreateUser`、自分自身への`iam:PutUserPermissionsBoundary`/`DeleteUserPermissionsBoundary`、許可リスト外のポリシー（例: `AmazonS3FullAccess`）の`AttachUserPolicy`は、いずれもBoundaryによって明示的に拒否される

### 経緯（このユーザーのIAM設定を将来触るときのために）

このセットアップに至るまでに2回、`myapp-deploy`自身のIAM操作権限が一時的に失われるミスがありました。

1. `AdministratorAccess`を外す際に自己管理権限を先に付け忘れ、一切のIAM操作ができなくなった
2. 復旧用インラインポリシーで`iam:PolicyName`条件キーを使ったが、これはAWSがサポートしていない条件キーで機能せず、インラインポリシー経由の自己管理が動作しなかった（幸い「条件不成立→拒否」という安全な壊れ方だった）

最終的に、カスタム管理ポリシー＋自身のARNをResourceに指定する方式（`myapp-deploy-billing`と同じパターン）に落ち着き、これは動作確認済みです。同じ轍を踏まないよう、この節を残しています。
