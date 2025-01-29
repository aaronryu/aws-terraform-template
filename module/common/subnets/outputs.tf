
output "pub_sub_0_id" {
  value = "${aws_subnet.public_subnet_0.id}"
}

output "pub_sub_1_id" {
  value = "${aws_subnet.public_subnet_1.id}"
}

output "pri_sub_0_id" {
  value = "${aws_subnet.private_subnet_0.id}"
}

output "pri_sub_1_id" {
  value = "${aws_subnet.private_subnet_1.id}"
}

