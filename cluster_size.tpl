${jsonencode(
{
    // This template specifies the available parameters for the different sizes of LogScale clusters
    // system_node          -> AKS system nodes for running system pod functions like coredns
    // logscale_digest      -> AKS nodes dedicated to core logscale systems (NVME attached storage) 
    // logscale_ingress     -> AKS nodes dedicated to proxy for access to control system access 
    // logscale_ingest      -> AKS nodes dedicated to logscale ingest nodes
    // logscale_ui          -> AKS nodes dedicated to UI nodes that do not handle data digest
    // strimzi_node         -> AKS nodes dedicated to strimzi kafka

    "xsmall": {
        // kafka nodes
        "kafka_broker_pod_replica_count": 3,
        "kafka_broker_resources": {"limits": {"cpu": 3, "memory": "24Gi"}, "requests": {"cpu": 3, "memory": "24Gi"}},
        "kafka_broker_data_disk_size": "1024Gi",
        "kafka_broker_disk_count": "1",
        "kafka_broker_data_storage_class": "topolvm-provisioner",

        // digest nodes
        "logscale_digest_pod_count": 3,
        "logscale_digest_data_disk_size": "1500Gi",
        "logscale_digest_resources": {"limits": {"cpu": 6, "memory": "48Gi"}, "requests": {"cpu": 6, "memory": "48Gi"}},
        "logscale_target_replication_factor": 2,

        // ingest nodes
        "logscale_ingest_pod_count": 3,
        "logscale_ingest_data_disk_size": "60Gi",
        "logscale_ingest_resources": {"limits": {"cpu": 6, "memory": "10Gi"}, "requests": {"cpu": 6, "memory": "10Gi"}},

        // ingress nodes
        "logscale_ingress_min_node_count": 2,
        "logscale_ingress_max_node_count": 3,
        "logscale_ingress_desired_node_count": 2,
        "logscale_ingress_data_disk_size": "64Gi",
        "logscale_ingress_resources": {"limits": {"cpu": 2, "memory": "4Gi"}, "requests": {"cpu": 2, "memory": "4Gi"}},
        "logscale_basic_ingress_resources": {"limits": {"cpu": 1, "memory": "1Gi"}, "requests": {"cpu": 1, "memory": "1Gi"}},

        // ui nodes
        "logscale_ui_pod_count": 2,
        "logscale_ui_data_disk_size": "60Gi",
        "logscale_ui_resources": {"limits": {"cpu": 3, "memory": "24Gi"}, "requests": {"cpu": 3, "memory": "24Gi"}},
    },

    "small": {
        // kafka nodes
        "kafka_broker_pod_replica_count": 5,
        "kafka_broker_resources": {"limits": {"cpu": 3, "memory": "24Gi"}, "requests": {"cpu": 3, "memory": "24Gi"}},
        "kafka_broker_data_disk_size": "1024Gi",
        "kafka_broker_disk_count": "2",
        "kafka_broker_data_storage_class": "topolvm-provisioner",

        // digest nodes
        "logscale_digest_pod_count": 6,
        "logscale_digest_data_disk_size": "3000Gi",
        "logscale_digest_resources": {"limits": {"cpu": 14, "memory": "100Gi"}, "requests": {"cpu": 14, "memory": "100Gi"}},
        "logscale_target_replication_factor": 2,

        // ingest nodes
        "logscale_ingest_pod_count": 6,
        "logscale_ingest_data_disk_size": "60Gi",
        "logscale_ingest_resources": {"limits": {"cpu": 6, "memory": "10Gi"}, "requests": {"cpu": 6, "memory": "10Gi"}},

        // ingress nodes
        "logscale_ingress_min_node_count": 3,
        "logscale_ingress_max_node_count": 21,
        "logscale_ingress_desired_node_count": 3,
        "logscale_ingress_data_disk_size": "64Gi",
        "logscale_ingress_resources": {"limits": {"cpu": 2, "memory": "4Gi"}, "requests": {"cpu": 2, "memory": "4Gi"}},
        "logscale_basic_ingress_resources": {"limits": {"cpu": 2, "memory": "2Gi"}, "requests": {"cpu": 2, "memory": "2Gi"}},

        // ui nodes
        "logscale_ui_pod_count": 3,
        "logscale_ui_data_disk_size": "128Gi",
        "logscale_ui_resources": {"limits": {"cpu": 3, "memory": "24Gi"}, "requests": {"cpu": 3, "memory": "24Gi"}},
    },
    "medium": {
        // kafka nodes    
        "kafka_broker_pod_replica_count": 15,
        "kafka_broker_resources": {"limits": {"cpu": 14, "memory": "102Gi"}, "requests": {"cpu": 14, "memory": "102Gi"}},
        "kafka_broker_data_disk_size": "1024Gi",
        "kafka_broker_disk_count": "4",
        "kafka_broker_data_storage_class": "topolvm-provisioner",

        // digest nodes
        "logscale_digest_pod_count":21,
        "logscale_digest_data_disk_size": "3000Gi",
        "logscale_digest_resources": {"limits": {"cpu": 14, "memory": "102Gi"}, "requests": {"cpu": 14, "memory": "102Gi"}},
        "logscale_target_replication_factor": 2,

        // ingest nodes
        "logscale_ingress_min_node_count": 6,
        "logscale_ingress_max_node_count": 33,
        "logscale_ingress_desired_node_count": 6,
        "logscale_ingest_pod_count": 15,
        "logscale_ingest_data_disk_size": "60Gi",
        "logscale_ingest_resources": {"limits": {"cpu": 14, "memory": "28Gi"}, "requests": {"cpu": 14, "memory": "28Gi"}},

        // ingress nodes
        "logscale_ingress_data_disk_size": "128Gi",
        "logscale_ingress_resources": {"limits": {"cpu": 6, "memory": "10Gi"}, "requests": {"cpu": 6, "memory": "10Gi"}},
        "logscale_basic_ingress_resources": {"limits": {"cpu": 2, "memory": "2Gi"}, "requests": {"cpu": 2, "memory": "2Gi"}},
        
        // ui nodes
        "logscale_ui_pod_count": 6,
        "logscale_ui_data_disk_size": "250Gi",
        "logscale_ui_resources": {"limits": {"cpu": 7, "memory": "56Gi"}, "requests": {"cpu": 7, "memory": "56Gi"}},
    },
    "large": {
        // kafka nodes
        "kafka_broker_pod_replica_count": 9,
        "kafka_broker_resources": {"limits": {"cpu": 14, "memory": "102Gi"}, "requests": {"cpu": 14, "memory": "102Gi"}},
        "kafka_broker_data_disk_size": "2048Gi",
        "kafka_broker_disk_count": "6",
        "kafka_broker_data_storage_class": "topolvm-provisioner",

        // digest nodes
        "logscale_digest_pod_count":42,
        "logscale_digest_data_disk_size": "6000Gi",
        "logscale_digest_resources": {"limits": {"cpu": 30, "memory": "240Gi"}, "requests": {"cpu": 30, "memory": "240Gi"}},
        "logscale_target_replication_factor": 2,

        // ingest nodes
        "logscale_ingest_pod_count": 15,
        "logscale_ingest_data_disk_size": "128Gi",
        "logscale_ingest_resources": {"limits": {"cpu": 30, "memory": "58Gi"}, "requests": {"cpu": 30, "memory": "58Gi"}},

        // ingress nodes
        "logscale_ingress_min_node_count": 6,
        "logscale_ingress_max_node_count": 33,
        "logscale_ingress_desired_node_count": 6,
        "logscale_ingress_data_disk_size": "128Gi",
        "logscale_ingress_resources": {"limits": {"cpu": 14, "memory": "22Gi"}, "requests": {"cpu": 14, "memory": "22Gi"}},
        "logscale_basic_ingress_resources": {"limits": {"cpu": 4, "memory": "8Gi"}, "requests": {"cpu": 4, "memory": "8Gi"}},
        
        // ui nodes
        "logscale_ui_pod_count": 9,
        "logscale_ui_data_disk_size": "250Gi",
        "logscale_ui_resources": {"limits": {"cpu": 14, "memory": "102Gi"}, "requests": {"cpu": 14, "memory": "102Gi"}},
    },
    "xlarge": {
        // kafka nodes
        "kafka_broker_pod_replica_count": 28,
        "kafka_broker_resources": {"limits": {"cpu": 14, "memory": "102Gi"}, "requests": {"cpu": 14, "memory": "102Gi"}},
        "kafka_broker_data_disk_size": "2048Gi",
        "kafka_broker_disk_count": "8",
        "kafka_broker_data_storage_class": "topolvm-provisioner",

        // digest nodes
        "logscale_digest_pod_count":78,
        "logscale_digest_data_disk_size": "12000Gi",
        "logscale_digest_resources": {"limits": {"cpu": 62, "memory": "500Gi"}, "requests": {"cpu": 62, "memory": "500Gi"}},
        "logscale_target_replication_factor": 2,

        // ingest nodes
        "logscale_ingest_pod_count": 18,
        "logscale_ingest_data_disk_size": "128Gi",
        "logscale_ingest_resources": {"limits": {"cpu": 46, "memory": "92Gi"}, "requests": {"cpu": 46, "memory": "92Gi"}},

        // ingress nodes
        "logscale_ingress_min_node_count": 9,
        "logscale_ingress_max_node_count": 60,
        "logscale_ingress_desired_node_count": 18,
        "logscale_ingress_data_disk_size": "128Gi",
        "logscale_ingress_resources": {"limits": {"cpu": 14, "memory": "22Gi"}, "requests": {"cpu": 14, "memory": "22Gi"}},
        "logscale_basic_ingress_resources": {"limits": {"cpu": 4, "memory": "8Gi"}, "requests": {"cpu": 4, "memory": "8Gi"}},
        
        // ui nodes
        "logscale_ui_pod_count": 18,
        "logscale_ui_data_disk_size": "500Gi",
        "logscale_ui_resources": {"limits": {"cpu": 18, "memory": "148Gi"}, "requests": {"cpu": 18, "memory": "148Gi"}},
    },
}
)}
