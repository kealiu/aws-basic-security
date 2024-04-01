import json
from jinja2 import Environment, FileSystemLoader

tfvars = ['regional/terraform.tfvars', 'global/terraform.tfvars']

def load_config():
    config = {}
    with open('config.json') as f:
        config = json.load(f)
    return config

def tfvars_init(tfvar, vars):
    environment = Environment(loader=FileSystemLoader("./"))
    template = environment.get_template(tfvar)
    return template.render(vars)

def main():
    config = load_config()
    regions = config.pop('region')
    aws_config_bucket_name = config['bucket_prefix']+'-'+config['account']+'-'+config['random_str']
    config['aws_config_bucket_name'] = aws_config_bucket_name
    for tmpl in tfvars:
        for region in regions: 
            v = dict(config)
            v['region'] = region
            tfvar = tfvars_init(tmpl+".tmpl", v)
            with open(tmpl, "w+") as f:
                f.write(tfvar)

if __name__ == "__main__":
    main()