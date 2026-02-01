# GoSlimStratum Agent
## Summary
GoSlimStratum Agent (GSSA) is an agent that collects data from private networks for miners, mim and GoSlimStratum instances and then sends that data to a cloud endpoint for external viewing by users.

This allows users to view what is going on with their miners, GSS instances and Servers without having access to their private network, using an IoT style approach

IoT Style:
Cloud Relay Pattern (most common)
The device maintains an outbound persistent connection to a cloud service. Since outbound connections from your home network work fine through NAT, the device connects to a cloud server and keeps that connection alive. When you access the device through a web app or mobile app, you're actually connecting to the cloud service, which relays commands and data through that established connection. This is how most consumer IoT products work - Ring doorbells, Nest thermostats, etc.

GSSA is the private agent side of the solution. GSSCloud will be the public side (TBD).

GSSA's only purpose in life is to collect data and send it to a cloud endpoint. It will also have a web interface to configure it, endpoints that can be called on the private network to view the data it will send to the cloud endpoints.

## Features
1. Collect data from mining devices
    - AxeOS devices
    - Canaan devices
    - Antminer devices

2. Collect data from GSS instances
    - GoSlimStratum instances

4. Collect data from MIM instances

5. Send that data to a cloud endpoint

6. Configurable for what devices, GSS & MIM instances

7. Token based for cloud access


## Future, perhaps allow configurations from the cloud side, back to the private devices / GSS instances

## Technology stack
1. GoLand native
2. Tailwinds CSS for any web interfaces
3. Should be stateless, no DB required
4. Lightweight and low memory footprint
5. Needs schedulers for various polling (configurable by device, application, etc)
6. JSON documents for all data outputs
7. Docker image capable, with externalized logs and config directories for persistance 
8. Binary builds / releases for Linux, MacOS and maybe Windows?

## Phased approach
### Phase 1
1. Data collection
    - Collect data from mining devices
    - Collect data from GSS instances
    - Collect data from MIM instances
2. Make that data viewable locally by API endpoints
3. Create web interface for configurations
4. Configuration structure, config.json

### Phase 2
1. Ability to send that data to a cloud endpoint.

