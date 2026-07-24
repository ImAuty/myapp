# infra

myappのAWSインフラ定義。学習目的で構築したECS Fargate + RDS構成から、ポートフォリオ公開時のコストを抑えるためEC2単体構成へ移行した経緯をそのまま残しています。

## ディレクトリ構成

- `fargate/` — 最初に構築した構成（ECS Fargate + RDS）。学習用に構築したもので、現在は稼働していません。
- `ec2/` — 現在稼働中の構成（EC2単体 + docker-compose）。コスト最適化のため移行しました。
- ルート直下の `aaaa-record.json` / `alias-record.json` / `cert-validation.json` — Route53 / ACM関連。ALBを経由する点はどちらの構成でも変わらないため共通で使用しています。

## 現在稼働中の構成

```
Route53 (myapp.imauty.com)
        │
        ▼
   ALB (myapp-alb, HTTPS/ACM)
        │
   ┌────┴────┐
   │ path-based routing (/api/* → backend)
   ▼         ▼
backend-tg  frontend-tg
   │         │
   └────┬────┘
        ▼
  EC2 (myapp-ec2, t4g.small)
  docker compose up -d
  ├─ db (postgres:16)
  ├─ backend  (8080)
  └─ frontend (3000)
```

ALB・Route53・ACM証明書はFargate構成時から流用し、背後のターゲットグループのみEC2インスタンス向けに差し替えています。

## 経緯

1. ECS Fargate + RDSでの構築（`fargate/`）— マネージドサービスでの構成をひと通り学習する目的
2. ポートフォリオとして公開するにあたり、Fargate + RDSは常時稼働コストが高いため、EC2単体（t4g.small）+ docker-composeへ移行（`ec2/`）
