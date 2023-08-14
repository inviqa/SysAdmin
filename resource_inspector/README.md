# Cloud Resource Fetch Scripts

This repository contains two bash scripts that allow you to easily fetch information
about your AWS and DigitalOcean resources.

- The `AWS` script, retrieves information via the AWS API. It extracts instances,
volumes, images, and snapshots relevant to specified or all regions.

- The `DigitalOcean` script, (`check_do_resources.sh`), uses the DigitalOcean API
to retrieve resources such as droplets, volumes, images, snapshots, and domains,
displaying the resource ID, name, and creation date.

The scripts are designed to operate with Unix-based systems, including macOS.

## Prerequisites

Before using these scripts, ensure that you have the following prerequisites:

1. **AWS Access key and Secret key**: Make sure you have configured the AWS CLI
on your local system.

   **DigitalOcean API key**: Obtain an API key for your DigitalOcean account and
   set it as an environment variable named `DIGITAL_OCEAN_API_KEY`.

2. `curl` command: The DO script uses `curl` command to make API requests.
Ensure `curl` is installed on your system.

3. `jq` command-line JSON processor: Both scripts work with `jq` for parsing API responses.
Ensure `jq` is installed and available.

4. AWS CLI: Ensure AWS CLI is installed and properly configured on your system.

## Usage

### AWS script

1. Make the script executable:

   ```shell
   chmod +x check_aws_resources.sh
   ```

2. Run the script:

```shell
./check_aws_resources.sh

```

   User specific AWS profile using option `-p or --profile` and specific region
   using `-r or --region`

```shell
./check_aws_resources.sh --profile demo-profile --region us-west-2
./check_aws_resources.sh -p demo-profile -r us-west-2
```

   Enable `DEBUG` or verbose mode can be invoked using option `-v or --verbose`

```shell
./check_aws_resources.sh --verbose
./check_aws_resources.sh -v
```

### DigitalOcean script

1. Set the `DIGITAL_OCEAN_API_KEY` environment variable with your DigitalOcean API key:

   ```shell
   export DIGITAL_OCEAN_API_KEY=your_api_key
   ```

2. Make the script executable:

   ```shell
   chmod +x check_do_resources.sh
   ```

3. Run the script:

   ```shell
   ./check_do_resources.sh
   ```

## Sample Output

Both scripts will display the fetched resources in various colors based on their age:

- Green: Less than 1 year old
- Blue: 1 to 2 years old
- Yellow: 2 to 3 years old
- Red: More than 3 years old

Here's an example of what you might see (actual results are anonymised):

> The standard output is provided in CSV format

### DigitalOcean Script

```csv
"region","created_at","age_in_years","resource_type","id","name"
"lon1","2017-04-27T05:44:29Z",6,"droplets",470659xx,"project-uk-prod"
"lon1","2017-05-11T07:33:30Z",6,"droplets",485128xx,"project-prod-test"
"lon1","2017-07-04T22:47:05Z",6,"droplets",540100xx,"project-ng"
"lon1","2017-10-30T18:58:22Z",4,"droplets",117269xx,"project-qa-test"
"lon1","2022-04-16T08:38:40Z",0,"droplets",188781xx,"test-tools"
```

### AWS Script

```csv
"region","created_at","age_in_years","resource_type","id","name"
"eu-west-2","2023-06-23T08:28:39.000Z",0,"images","ami-01493bexxxaeffe0da","incubator-jenkins-runner-amd64-xxxx"
"eu-west-2","2023-06-23T08:29:26.000Z",0,"images","ami-097e434bxxxx68886","incubator-jenkins-runner-amd64-xxxx"
"eu-west-2","2023-06-23T12:32:19.000Z",0,"images","ami-0b9a9652xxxxxd460","incubator-jenkins-runner-arm64-xxxx"
"eu-west-2","2022-05-09T17:04:36.556000+00:00",1,"snapshots","snap-0c94ad5xxxxd713f0","Created by CreateImage(i-09ebfef4xxxxx241ca) for ami-09da1e6cxxxxx9259"
"eu-west-2","2022-05-09T17:09:10.955000+00:00",1,"snapshots","snap-0c52859ffxxxxe9fa","Created by CreateImage(i-0e9348xxxxx7e43d4) for ami-0609f9b7xxxxx4b24"
```

## Notes

- Make sure you have a stable internet connection to successfully fetch
the DigitalOcean and AWS resources.

- Ensure that the Access credentials you provide have the necessary permissions
to access the resources you wish to retrieve.

- These scripts use Unix-compatible commands and may not work as expected
on Windows-based systems.

## License

These scripts are licensed under the [MIT License](https://opensource.org/licenses/MIT)
and [GPL License](https://www.gnu.org/licenses/gpl-3.0.html).

---
