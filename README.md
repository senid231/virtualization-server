# Virtualization Server

This application provides a REST API that communicates with the libvirt daemon to create, modify, and delete virtual machines.

It assumes that you have libvirt installed and configured along the lines of [this](https://brooks.sh/2017/12/22/configuring-kvm-on-clear-linux/) blog post.

## API Documentation

### Virtual Machines

The `/virtual_machines/` namespace is where all CRUD operations for a virtual machine and their dependents live.

#### List all virtual machines

Request:

```
$ curl -s http://localhost:4567/virtual_machines
```

Response:

```
200 OK
```

```json
[
  {
    "uuid": "2de02519-c347-432c-9923-3753c3538e02",
    "state": "shut off",
    "cpu_count": 2,
    "memory_size": 8388608,
    "nics": [
      {
        "uuid": "82df3d26-764e-4748-9a4b-d530a99f664d",
        "mac_address": "02:df:38:20:b3:f9",
        "source": "kvm_bridge"
      }
    ],
    "disks": [
      {
        "uuid": "3fd739d9-ae7a-4304-b0ad-c92b9ee9c138",
        "size": 10485760
      }
    ]
  }
]
```

#### View a single virtual machine

Request:

```
$ curl -s http://localhost:4567/virtual_machines/2de02519-c347-432c-9923-3753c3538e02
```

Response:

```
200 OK
```

```json
{
  "uuid": "2de02519-c347-432c-9923-3753c3538e02",
  "state": "shut off",
  "cpu_count": 2,
  "memory_size": 8388608,
  "nics": [
    {
      "uuid": "82df3d26-764e-4748-9a4b-d530a99f664d",
      "mac_address": "02:df:38:20:b3:f9",
      "source": "kvm_bridge"
    }
  ],
  "disks": [
    {
      "uuid": "3fd739d9-ae7a-4304-b0ad-c92b9ee9c138",
      "size": 10485760
    }
  ]
}
```

#### Create a virtual machine

Request:

```
$ curl -s http://localhost:4567/virtual_machines -X POST -d '{"cpu_count": 2, "memory_size": 8388608}'
```

Response:

```
201 Created
```

```json
{
  "uuid": "2de02519-c347-432c-9923-3753c3538e02",
  "state": "shut off",
  "cpu_count": 2,
  "memory_size": 8388608,
  "nics": [
    {
      "uuid": "82df3d26-764e-4748-9a4b-d530a99f664d",
      "mac_address": "02:df:38:20:b3:f9",
      "source": "kvm_bridge"
    }
  ],
  "disks": [
    {
      "uuid": "3fd739d9-ae7a-4304-b0ad-c92b9ee9c138",
      "size": 10485760
    }
  ]
}
```

#### Update a virtual machine

Request:

```
$ curl -s http://localhost:4567/virtual_machines/2de02519-c347-432c-9923-3753c3538e02 -X PATCH -d '{"state":"started"}'
```

##### Input

| Name | Type | Description |
|------|------|-------------|
| `state` | `string` | The state of the virtual machine. Can be one of `started`, `stopped` (graceful), or `halted` (forced).

Response:

```
200 OK
```

```json
{
  "uuid": "2de02519-c347-432c-9923-3753c3538e02",
  "state": "started",
  "cpu_count": 2,
  "memory_size": 8388608,
  "nics": [
    {
      "uuid": "82df3d26-764e-4748-9a4b-d530a99f664d",
      "mac_address": "02:df:38:20:b3:f9",
      "source": "kvm_bridge"
    }
  ],
  "disks": [
    {
      "uuid": "3fd739d9-ae7a-4304-b0ad-c92b9ee9c138",
      "size": 10485760
    }
  ]
}
```

#### Destroy a virtual machine

Request:

```
$ curl -s http://localhost:4567/virtual_machines/2de02519-c347-432c-9923-3753c3538e02 -X DELETE
```

Response:

```
200 OK
```

## Setup

### Bootstrapping

```
git clone https://github.com/neptune-networks/virtualization-server
script/bootstrap
```

### Running the server

```
script/server
```

### Running tests

```
script/test
```
