module "qa" {
    source = "../modules/blog"

    env = {
        name           = "qa"
        network_prefix = "10.1"
    }

    asg_settings = {
        min_size         = 1
        max_size         = 1
        desired_capacity = 1
    }
}