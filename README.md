# Export to Event Streams

## Introduction

You can use **Export to Event Streams** to periodically read the logs (or events) from IBM Log Analysis (or IBM Cloud Activity Tracker), and write them to an Event Streams instance.  It uses IBM Cloud Function to periodically read the logs from Logging service using the Export API.  These logs are written to your Event Streams instance, where you can use them for other applications.

> The logs from IBM Cloud Activity Tracker are usually called "events".
> In this page, the term "logs" will refer generically to either logs from IBM Log Analysis or events from IBM Cloud Activity Tracker.)

![high-level-design](diagrams/logdna_streaming_cloud_func.png?raw=true])

As illustrated, the `Export to Event Streams` has following components:

1. IBM Cloud Analysis or IBM Cloud Activity Tracker (as the log source)
1. IBM Cloud Function (to run Action & Trigger)
1. IBM Cloud Event Streams. (as the log sink)

This repo automates the deployment of the `Export to Event Streams` capability using Terraform & IBM Cloud Schematics.

## Prerequisites
- You must have one of the following log sources already provisioned, in the preferred region / locatoin:
  - [IBM Log Analysis](https://cloud.ibm.com/observe/logging)
  - [IBM Cloud Activity Tracker](https://cloud.ibm.com/observe/activitytracker)
- You must have a service key from the log source. To get the service key (`logging_service_key`):
  - Open the LogDNA UI.
  - Select the gear icon on the left, then Organization > API Keys.
  - Create a service key, if you don't have one.
  - Copy the service key and save it. This is your `logging_service_key`.
- You must have an IBM Cloud API key for your account. To get an IBM Cloud API key (`ibmcloud_api_key`):
  - Open the [IBM Cloud Console](https://cloud.ibm.com)
  - Select Manage > Access (IAM) > API Keys.
  - Use the "Create an IBM Cloud API key" button, and fill in the Name and Description.
  - Copy the API key and save it. This is your `ibmcloud_api_key`.
- You must have an Event Streams (Enterprise plan) instance, as a log sink.
  - The name of the Event Streams instance is your `event_stream_name`.
  - If you don't have an IBM Event Streams instance in your account, refer to [create Event Streams instance](https://cloud.ibm.com/docs/EventStreams?topic=EventStreams-getting_started) to provision a new IBM Event Streams instance; select the Enterprise plan.

## Deploy _Export to Event Streams_ using IBM Cloud Schematics

1. Click on [Deploy to IBM Cloud](https://cloud.ibm.com/schematics/workspaces/create?repository=https://github.com/IBM/export-to-eventstreams&terraform_version=terraform_v0.13) to create a new Schematics Workspace for _Export to Event Streams_.  By default, the following parameters will be pre-filled :
   * Repository URL (cannot be changed)
   * IBM Cloud Account (`ibmcloud_account`, displayed on the right-top corner of the IBM Cloud Console - can be changed)
   * Workspace name (`workspace_name` - can be changed)
   * Workspace tags (`workspace_tags` - can be changed)
   * Workspace resource group (`workspace_resource_group` for the workspace - can be changed)
   * Workspace location (`workspace_region` for the workspace - can be changed)
   > Note: The `workspace_tags`, `workspace_resource_group` & `workspace_region` - is independent, and is not related to the Logging & Event Streams services parameters.
1. Review the following input variables (Workspace -> Settings -> Variables), and update them according to your needs:
   | Input variable	    | Description	           | Type	  | Default | Required ? | Sensitive ? |
   |--------------------|------------------------|--------|---------|------------|-------------|
   | ibmcloud_api_key   | Enter your IBM Cloud API Key, you can get your IBM Cloud API key using: https://cloud.ibm.com/iam#/apikeys | String |  | Yes | Yes |
   | logging_service_key | Service key to connect to the source logging service instance | String |  | Yes | Yes |
   | logging_region      | Region of the source logging service instance (us-south, eu-de, etc.) | String | us-south | Yes | No |
   | event_stream_name   | Name of target Event Stream instance | String |   | Yes | No |
   | event_stream_region | Region of the target Event Stream instance (us-south, eu-de, etc.) | String | us-south | Yes | No |
   | event_stream_topic  |  Name of the target event stream topic | String | export_logs | Yes | No |
   | event_stream_resource_group | Resource Group name of the target Event Stream instance  | String | Default | Yes | No |
   | event_stream_retention | Log retention time (between 1 to 30 days) settings for the target Event Stream instance (in days) | Number |  | No | No |
   | buffer_time        | Buffer time for processing by streaming engine (in minutes) | Number | 15 | Yes | No |
1. Click the "Save Changes".
1. Click "Generate Plan".
1. Click the "Apply Plan".
1. Monitor the progress by clicking "View log".

On successful deployment,
* You will see the following log messages in Schematic workspace logs.
   ![workspace-successful-status](diagrams/workspace_status.png?raw=true])
* You will see the following additional service instances in the [Resource List](https://cloud.ibm.com/resources) page.
   - Cloud Function Namespace : export_event_streams
   - Schematics workspaces : `workspace_name`

### Access permissions

You must provide the following minimum permissions, for any delegated user, to successfully deploy the _Export to Event Streams_ capability using the Terraform-based automation.
| Cloud Services       | Resource Group                | Permission                |
|----------------------|-------------------------------|---------------------------|
| Schematics           | `workspace_resource_group`    | Service role: Manager     |
| Cloud Functions      | (for Service instance)        | Platform role : Administrator </br> Service role: Manager |
| Event Streams        | (for Service instance)        | Platform role : Editor    |
| Event Streams Topic  | `event_stream_resource_group` | Service role: Manager |


## Remove _Export to Event Streams_ using IBM Cloud Schematics
1. Open [IBM Cloud Schematics workspace](https://cloud.ibm.com/schematics/workspaces)
1. In the workspace list, select the `workspace_name` previously entered for this _Export to Event Streams_ capability, and press `Delete`
1. In the "Delete Workspace" pop-up window,
    - Select 'Delete workspace'
    - Select 'Delete all associated resources'
    - Type the `workspace_name` and press the `Delete` button

---

## Log Export considerations

The Export API depends on the logs already being stored. For this reason the Cloud Function retrieves logs that are timestamped in the past by an interval known as the `buffer_time`. If the `buffer_time` is 15 minutes, then the Cloud Function is continually getting logs timestamped 15 minutes ago. This gives the logs 15 minutes to be stored.

A `buffer_time` of 15 minutes usually achieves a high retrieval rate of logs. However, logs will occasionally take longer to be transmitted and stored. In this case, those logs will not be included in Event Streams. If this becomes a concern, you may wish to increase the `buffer_time`.

Do not deploy `Export to Event Streams` multilpe instances to one LogDNA instance. Export API might return the 429 error and data might not be exported.

### Design details

* Cloud Function runs in every 60 seconds using the Cloud Function Trigger.
* Cloud Function calls the Export API 12 times (5 sec logs in each call).
