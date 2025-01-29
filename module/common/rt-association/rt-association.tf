resource "aws_route_table_association" "pub_0_association" {
    route_table_id = var.pub_rt_id
    subnet_id = var.pub_sub_0_id
}

resource "aws_route_table_association" "pub_1_association" {
    route_table_id = var.pub_rt_id
    subnet_id = var.pub_sub_1_id
}

resource "aws_route_table_association" "pri_0_association" {
    route_table_id = var.pri_rt_id
    subnet_id = var.pri_sub_0_id
}

resource "aws_route_table_association" "pri_1_association" {
    route_table_id = var.pri_rt_id
    subnet_id = var.pri_sub_1_id
}