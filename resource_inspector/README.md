# DigitalOcean Resource Fetch Script

This bash script allows you to easily fetch information about your DigitalOcean resources using the DigitalOcean API. It retrieves various resource types such as droplets, volumes, images, snapshots, and domains, and displays relevant information such as the resource ID, name, and creation date. The script is designed to be compatible with Unix-based systems, including macOS.

## Prerequisites

Before using this script, ensure that you have the following prerequisites:

1. DigitalOcean API key: Obtain an API key from your DigitalOcean account. Set it as an environment variable named `DIGITAL_OCEAN_API_KEY`.

2. `curl` command: The script uses the `curl` command to make API requests. Verify that `curl` is installed on your system.

3. `jq` command-line JSON processor: The script relies on `jq` for parsing the API responses. Make sure `jq` is installed and accessible.

## Usage

1. Set the `DIGITAL_OCEAN_API_KEY` environment variable with your DigitalOcean API key:

   ```shell
   export DIGITAL_OCEAN_API_KEY=your_api_key
   ```

2. Make the script executable:

   ```shell
   chmod +x check_digital_ocean_resources.sh
   ```

3. Run the script:

   ```shell
   ./check_digital_ocean_resources.sh
   ```

## Sample Output

The script will display the fetched resources in various colors based on their age:

- Green: Less than 1 year old
- Blue: 1 to 2 years old
- Yellow: 2 to 3 years old
- Red: More than 3 years old

Here's an example of the output:

```
droplets: 1234 sample-droplet-1 2021-01-10T10:20:30Z
volumes: 5678 sample-volume-1 2020-06-15T08:40:50Z
images: 9012 sample-image-1 2019-03-01T12:30:45Z
snapshots: 3456 sample-snapshot-1 2018-02-05T15:50:10Z
domains: 7890 sample-domain-1 2017-04-20T18:25:35Z
```

## Notes

- Make sure you have a stable internet connection to successfully fetch the DigitalOcean resources.
- Ensure that the DigitalOcean API key you provide has the necessary permissions to access the resources you wish to retrieve.
- This script uses Unix-compatible commands and may not work as expected on Windows-based systems.

## License

This script is licensed under the [MIT License](https://opensource.org/licenses/MIT) and [GPL License](https://www.gnu.org/licenses/gpl-3.0.html).
