# RookCeph

https://microk8s.io/docs/addon-rook-ceph
https://github.com/rook/rook
https://rook.io/docs/rook/latest-release/Getting-Started/intro/
https://rook.io/docs/rook/latest-release/Getting-Started/quickstart/#deploy-the-rook-operator
https://microk8s.io/docs/how-to-ceph
https://docs.ceph.com/en/reef/
https://canonical-microceph.readthedocs-hosted.com/en/latest/tutorial/get-started/


1242  sudo snap install microceph
 1243  sudo snap refresh --hold microceph
 1244  sudo microceph cluster bootstrap
 1245  sudo microceph status
 1246  sudo microceph disk add loop,4G,3
 1247  sudo microceph status
 1250  sudo microceph enable rgw --port 8080
 1251  sudo microceph status
 1252  sudo radosgw-admin user create --uid=user --display-name=user


alfred@k8s:~$ sudo radosgw-admin user create --uid=user --display-name=user
{
    "user_id": "user",
    "display_name": "user",
    "email": "",
    "suspended": 0,
    "max_buckets": 1000,
    "subusers": [],
    "keys": [
        {
            "user": "user",
            "access_key": "PES8OPI1W5P0UOK86QM7",
            "secret_key": "1ueTwvbp2cw3p6o1yoYEborFPDQ7ThqfSLQ9bkei",
            "active": true,
            "create_date": "2025-05-30T18:28:48.231865Z"
        }
    ],
    "swift_keys": [],
    "caps": [],
    "op_mask": "read, write, delete",
    "default_placement": "",
    "default_storage_class": "",
    "placement_tags": [],
    "bucket_quota": {
        "enabled": false,
        "check_on_raw": false,
        "max_size": -1,
        "max_size_kb": 0,
        "max_objects": -1
    },
    "user_quota": {
        "enabled": false,
        "check_on_raw": false,
        "max_size": -1,
        "max_size_kb": 0,
        "max_objects": -1
    },
    "temp_url_keys": [],
    "type": "rgw",
    "mfa_ids": [],
    "account_id": "",
    "path": "/",
    "create_date": "2025-05-30T18:28:48.231316Z",
    "tags": [],
    "group_ids": []
}

alfred@k8s:~$ sudo radosgw-admin key create --uid=user --key-type=s3 --access-key=foo --secret-key=bar
{
    "user_id": "user",
    "display_name": "user",
    "email": "",
    "suspended": 0,
    "max_buckets": 1000,
    "subusers": [],
    "keys": [
        {
            "user": "user",
            "access_key": "PES8OPI1W5P0UOK86QM7",
            "secret_key": "1ueTwvbp2cw3p6o1yoYEborFPDQ7ThqfSLQ9bkei",
            "active": true,
            "create_date": "2025-05-30T18:28:48.231865Z"
        },
        {
            "user": "user",
            "access_key": "foo",
            "secret_key": "bar",
            "active": true,
            "create_date": "2025-05-30T18:30:04.976675Z"
        }
    ],
    "swift_keys": [],
    "caps": [],
    "op_mask": "read, write, delete",
    "default_placement": "",
    "default_storage_class": "",
    "placement_tags": [],
    "bucket_quota": {
        "enabled": false,
        "check_on_raw": false,
        "max_size": -1,
        "max_size_kb": 0,
        "max_objects": -1
    },
    "user_quota": {
        "enabled": false,
        "check_on_raw": false,
        "max_size": -1,
        "max_size_kb": 0,
        "max_objects": -1
    },
    "temp_url_keys": [],
    "type": "rgw",
    "mfa_ids": [],
    "account_id": "",
    "path": "/",
    "create_date": "2025-05-30T18:28:48.231316Z",
    "tags": [],
    "group_ids": []
}

alfred@k8s:~$ curl http://192.168.178.200:8080
<?xml version="1.0" encoding="UTF-8"?><ListAllMyBucketsResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/"><Owner><ID>anonymous</ID></Owner><Buckets></Buckets></ListAllMyBucketsResult>
alfred@k8s:~$ 


