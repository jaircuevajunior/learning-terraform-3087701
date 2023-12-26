output "instance_ids2" {
    description = "id das instancias ec2 single"
    value = data.aws_instances.blog_instances.id
}

output "outro" {
    description = "test"
    value = data.aws_ami.app_ami.id
}