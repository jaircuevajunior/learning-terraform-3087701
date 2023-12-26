output "instance_ids2" {
    description = "id das instancias ec2"
    value = data.aws_instances.blog_instances.ids
}