# Config

Here you will find all the ansible configurations

| File             | Description                       |
|------------------|-----------------------------------|
| site.yaml        | Settings for Site (all instances) |
| alpine.yaml      | Settings for alpine instances     |
| ubuntu.yaml      | Settings for ubuntu instances     |
| kubernetes.yaml  | Settings for kubernets instances  |

Directory structure contains

```bash
.
├── alpine.yaml
├── ansible.cfg
├── filter_plugins
├── inventories
│   ├── infrastructure
│   │   ├── group_vars
│   │   │   └── README.md
│   │   ├── hosts
│   │   ├── host_vars
│   │   │   └── README.md
│   │   └── README.md
│   ├── production
│   │   ├── group_vars
│   │   │   └── README.md
│   │   ├── hosts
│   │   ├── host_vars
│   │   │   └── README.md
│   │   └── README.md
│   └── README.md
├── kubernetes.yaml
├── library
│   └── README.md
├── module_utils
│   └── README.md
├── README.md
├── roles
│   └── README.md
├── site.yaml
└── ubuntu.yaml
```bash
