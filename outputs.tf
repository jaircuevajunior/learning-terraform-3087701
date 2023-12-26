output "target_group_ids" {
    description = "test"
    value = [module.blog_alb.target_groups.ex-instance.id]
}