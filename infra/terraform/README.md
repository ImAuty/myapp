# infra/terraform

現在稼働中のAWS構成（EC2単体版、`../ec2/`のJSONで記録していたもの）をコード化したもの。VPC/サブネット/IGW/ルートテーブル/セキュリティグループ/EC2/ALB/ターゲットグループ/リスナー/ACM証明書/Route53レコード/ECRリポジトリまでを管理します。

State はローカル管理です（S3バックエンド等は未導入）。個人ポートフォリオ規模のため、追加のAWSリソース（S3+DynamoDB）を常時稼働させるコストを避けています。

Fargate + RDS構成（`../fargate/`）は現在停止中のため、このTerraformの対象外です。

## セットアップ

```bash
cd infra/terraform
cp terraform.tfvars.example terraform.tfvars
# terraform.tfvars を編集し、admin_ssh_cidr に自分のグローバルIPを設定
terraform init
```

## 既存リソースの取り込み（import）

このコードは「今動いているものをそのまま記述した」ものなので、`apply`ではなく`import`で既存リソースをstateに取り込みます。`import`はAWS側を変更しません（stateに記録するだけ）。

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
terraform import aws_lb_target_group_attachment.backend arn:aws:elasticloadbalancing:ap-northeast-1:743334887511:targetgroup/myapp-ec2-backend-tg/390cbad157e40dcc/i-00f1842abeaac406f/8080
terraform import aws_lb_target_group_attachment.frontend arn:aws:elasticloadbalancing:ap-northeast-1:743334887511:targetgroup/myapp-ec2-frontend-tg/3a6828b8cbb1a7bc/i-00f1842abeaac406f/3000
terraform import aws_lb_listener.http arn:aws:elasticloadbalancing:ap-northeast-1:743334887511:listener/app/myapp-alb/7165ca8f183ff38d/2417d4ad9518b0d0
terraform import aws_lb_listener.https arn:aws:elasticloadbalancing:ap-northeast-1:743334887511:listener/app/myapp-alb/7165ca8f183ff38d/ad6f41529d112ac9
terraform import aws_lb_listener_rule.api_to_backend arn:aws:elasticloadbalancing:ap-northeast-1:743334887511:listener-rule/app/myapp-alb/7165ca8f183ff38d/ad6f41529d112ac9/574b7ac26a142036
terraform import aws_acm_certificate.main arn:aws:acm:ap-northeast-1:743334887511:certificate/86081b1a-0dac-4438-b449-9a8274cef6e4
terraform import aws_route53_record.app_a Z05506923OMK303C1PA83_myapp.imauty.com_A
terraform import aws_route53_record.app_aaaa Z05506923OMK303C1PA83_myapp.imauty.com_AAAA
terraform import 'aws_route53_record.cert_validation["myapp.imauty.com"]' Z05506923OMK303C1PA83__296c60637e52ff1f9756a1dffb04eb5b.myapp.imauty.com_CNAME
terraform import aws_ecr_repository.backend myapp-backend
terraform import aws_ecr_repository.frontend myapp-frontend
```

## import後にやること

```bash
terraform plan
```

を実行し、差分がないか確認してください。タグや細かい属性で差分が出ることがありますが、**`terraform apply`は必ず差分の内容を読んでから**実行してください。ここは本番稼働中のポートフォリオサイトを載せているインスタンスなので、意図しない`apply`はサービス停止やデータ消失（DBもこのEC2上にあるため）につながります。
