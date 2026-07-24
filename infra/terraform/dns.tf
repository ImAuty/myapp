data "aws_route53_zone" "main" {
  name         = "${var.route53_zone_name}."
  private_zone = false
}

resource "aws_route53_record" "app_a" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "app_aaaa" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "AAAA"

  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "cert_validation" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "_296c60637e52ff1f9756a1dffb04eb5b.${var.domain_name}"
  type    = "CNAME"
  records = ["_a719abce31cd15ae06b7a2b9a45970ef.jkddzztszm.acm-validations.aws."]
  ttl     = 300
}
