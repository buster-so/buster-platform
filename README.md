![Buster GitHub Banner](/assets/image.png)

<div align="center"><h1>Buster Warehouse</h1></div>
<div align="center"><h4>A data warehouse built on Apache Iceberg and Starrocks</h4></div>

<div align="center">
   <div>
      <h3>
         <a href="https://www.buster.so/get-started">
            <strong>Sign up</strong>
         </a> · 
         <a href="https://github.com/buster-labs/buster-warehouse">
            <strong>Quickstart</strong>
         </a> · 
         <a href="https://github.com/buster-labs/buster-warehouse">
            <strong>Deployment</strong>
         </a>
      </h3>
   </div>

   <div>
      <a href="https://github.com/buster-so/warehouse/blob/main/LICENSE"><img src="https://img.shields.io/badge/License-MIT-red.svg?style=flat-square" alt="MIT License"></a>
      <a href="https://www.ycombinator.com/companies/buster"><img src="https://img.shields.io/badge/Y%20Combinator-W24-orange?style=flat-square" alt="Y Combinator W23"></a>
   </div>
</div>
</br>

## Buster Warehouse Overview

This project is a data warehouse built on Apache Iceberg and Starrocks. In working with our customers, we found that Snowflake, Bigquery, and other warehouse solutions were prohibitively expensive or slow in them being able to deploy AI-powered analytics at scale.

Additionaly, we found that having a close integration between the data warehouse and our AI-native BI tool allows for a better and more reliable data experience.

### Key Features

- **Built on Starrocks:** We felt that Starrock was the best query engine by default for our use case. The main thing that pushed us towards it was that they perform predicate pushdown on iceberg tables, whereas Clickhouse and DuckDB do not.  We were also impressed by the performance, caching system, and flexibility of Starrocks.
- **Built on Apache Iceberg:** Some of the top companies in the world use Apache Iceberg for storing and interacting with their data.  We wanted a table format that not only brought tremendous benefits, but one that companies wouldn't outgrow.
- **Bring Your Own Storage:** We felt that customers should own their data and not be locked into a particular storage engine.

## Quickstart
Have 


## Roadmap

Currently, we are in the process of open-sourcing the platform.  This includes:

- Warehouse Product (This Repo) ✅
- BI platform (https://buster.so) ⏰

After that, we will release an official roadmap.

## How We Plan to Make Money

Currently, we offer a few commercial products:
- Cloud-Hosted Version
  - Cluster
  - Serverless
- Managed Self-Hosted Version

## Support and feedback

You can contact us through either:

- [Github Discussions](https://github.com/orgs/buster-so/discussions)
- Email us at founders at buster dot com

## License

This repository is MIT licensed, except for the `ee` folders. See [LICENSE](LICENSE) for more details.

## Shoutouts

The documentation from the Starrocks, Iceberg, and PyIceberg team has been very helpful in building this project.
