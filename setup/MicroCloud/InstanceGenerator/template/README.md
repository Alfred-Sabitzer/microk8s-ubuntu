# LXD Instance Generator - Templates

Each template consists of several parts. These files are placed in the right place

````bash
tree
.
├── files                                   # These are the standard files for all - source
│   ├── 90-sshd.conf                        # configuration for the ssh deamon
│   ├── bash_aliases                        # bash_aliases - common appreviations
│   ├── bash_logout                         # standard logout action
│   ├── bashrc                              # standard settings for loggin
│   ├── lsd_init.sh                         # initialization procedure
│   └── profile                             # standard login action
├── image                                   # Definition for the individual images
│   ├── alpine_image.yaml                   # image definition for alpine
│   ├── alpine_launch.yaml                  # launch mnemonic for alpine
│   ├── alpine_runcmd.yaml                  # run commandos to start alpine
│   ├── ubuntu_image.yaml                   # image definition for ubuntu
│   └── ubuntu_launch.yaml                  # launch mnemonic for ubuntu
├── profile                                 # settings for the individual profiles
│   ├── default                             # profile "default"
│   │   ├── config                          # configuration settings
│   │   │   └── cloud-init.user-data        # all for cloud-init.user-data
│   │   │       ├── cloud-config.yaml       # standard cloud config
│   │   │       ├── groups.yaml             # standard groups for all
│   │   │       ├── packages.yaml           # standard packages for all
│   │   │       └── users.yaml              # standard users for all
│   │   ├── devices.yaml                    # device configuration
│   │   ├── profile.yaml                    # profile settings
│   │   └── write_files.yaml                # standard files needed for all - include
│   └── infrastructure                      # profile "infrastructure"
│       ├── config                          # configuration settings
│       │   └── cloud-init.user-data        # all for cloud-init.user-data
│       │       ├── cloud-config.yaml       # standard cloud config
│       │       ├── groups.yaml             # standard groups for all
│       │       ├── packages.yaml           # standard packages for all
│       │       └── users.yaml              # standard users for all
│       ├── devices.yaml                    # device configuration
│       ├── profile.yaml                    # profile settings
│       └── write_files.yaml                # standard files needed for all - include
└── README.md

10 directories, 26 files

````

Every file can be superseded in the action instance configuration

Good examples are https://github.com/Alfred-Sabitzer/microk8s-ubuntu/tree/main/setup/MicroCloud/LXCInstances/demoalpine 
and https://github.com/Alfred-Sabitzer/microk8s-ubuntu/tree/main/setup/MicroCloud/LXCInstances/demoreplace
and https://github.com/Alfred-Sabitzer/microk8s-ubuntu/tree/main/setup/MicroCloud/LXCInstances/demostandard


# Include Directories

to include directories the file write_directory.yaml has to exist.

````bash
      # demodirectory
      - directory: /root/config
        owner: root:root
        content: config
````

directory is the place to be within the instance.
owner is the owner of the directory and all content in it.
content ist the name of the directory (located in the template-folder).

A working example is https://github.com/Alfred-Sabitzer/microk8s-ubuntu/tree/main/setup/MicroCloud/LXCInstances/demodirectory


