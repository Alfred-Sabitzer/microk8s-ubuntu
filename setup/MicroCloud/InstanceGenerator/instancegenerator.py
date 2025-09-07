import yaml
import os
from datetime import datetime
import os
import sys
import getopt

def load_template(template_dir, name):
    path = os.path.join(template_dir, f"{name}.yaml")
    with open(path, 'r') as f:
        return yaml.safe_load(f)

def generate_instance_yaml(project, profile, image, template_dir, output_file):
    project_data = load_template(template_dir, project)
    profile_data = load_template(template_dir, profile)
    image_data = load_template(template_dir, image)

    instance_config = {
        'project': project_data,
        'profiles': [profile_data],
        'image': image_data
    }

    with open(output_file, 'w') as f:
        yaml.dump(instance_config, f, default_flow_style=False)


def main(argv):
    opts, args = getopt.getopt(argv,"h:o:p:n:i:t:d:f",["help","project=","profile=","network=","image=","type=","template_dir=","output_file="])
    project="default"
    profile="default"
    network="default"  
    image="ubuntu"
    type="minimal"
    template_dir="./templates"
    output_file="instance.yaml"

    for opt, arg in opts:
        if opt in ("-h", "--help"):
            print("Usage: --project=<LXD project> --profile=<LXD profile> --network=<LXD network> --image=<LXD Image Name> --type=<minimal or full> --template_dir=<default .template> --output_file=<default instance.yaml>")
            sys.exit()
        elif opt in ("-o", "--project"):
            project = arg
        elif opt in ("-p", "--profile"):
            profile = arg
        elif opt in ("-n", "--network"):
            network = arg
        elif opt in ("-i", "--image"):
            image = arg
        elif opt in ("-t", "--type"):
            type = arg
        elif opt in ("-d", "--template_dir"):
            template_dir = arg
        elif opt in ("-f", "--output_file"):
            output_file = arg
    generate_instance_yaml(project, profile, image, template_dir, output_file)

if __name__ == "__main__":
    if len(sys.argv) > 2:
        main(sys.argv[1:])
    else:
        print("Usage: --project=<LXD project> --profile=<LXD profile> --network=<LXD network> --image=<LXD Image Name> --type=<minimal or full> --template_dir=<default .template> --output_file=<default instance.yaml>")
