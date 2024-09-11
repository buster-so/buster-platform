![Buster GitHub Banner](/assets/image.png)

<div align="center"><h1>The Buster Platform</h1></div>
<div align="center"><h4>A modern analytics platform for AI-powered data applications</h4></div>

<div align="center">
   <div>
      <h3>
         <a href="https://www.buster.so/get-started">
            <strong>Sign up</strong>
         </a> · 
         <a href="#quickstart">
            <strong>Quickstart</strong>
         </a> · 
         <a href="#deployment">
            <strong>Deployment</strong>
         </a>
      </h3>
   </div>

   <div>
      <a href="https://github.com/buster-so/warehouse/blob/main/LICENSE"><img src="https://img.shields.io/badge/License-MIT-red.svg?style=flat-square" alt="MIT License"></a>
      <a href="https://www.ycombinator.com/companies/buster"><img src="https://img.shields.io/badge/Y%20Combinator-W24-orange?style=flat-square" alt="Y Combinator W24"></a>
   </div>
</div>
</br>

## What is Buster?

Buster is a modern analytics platform built from the ground up with AI in mind.

We've spent the last two years working with companies to help them implement Large Language Models in their data stack.  This has mainly revolved around truly self-serve experiences that are powered by Large Language Models.  We've noticed a few pain points when it comes to the tools that are available today:

1. Slapping an AI copilot on top of existing BI tools can often result in a subpar experience for users. To deploy a powerful analytics experience, we believe that the entire app needs to be built from the ground up with AI in mind. 
2. Most organizations can't deploy ad-hoc, self-serve experiences for their users because their warehousing costs/performance are too prohibitive.  We believe that new storage formats like Apache Iceberg and query engines like Starrocks and DuckDB have the potential to change data warehousing and make it more accessible for the type of workloads that come with AI-powered analytics experiences.
3. The current CI/CD process for most analytics stacks struggle to keep up with changes and often result in broken dashboards, slow query performance, and other issues.  Introducing hundreds, if not thousands of user queries made with Large Language Models can exacerbate these issues and make it nearly impossible to maintain. We believe there is a huge opportunity to rethink how Large Language Models can be used to improve this process with workflows around self-healing, model suggestions, and more.
4. Current tools don't have tooling or workflows built around augmenting data teams.  They are designed for the analyst to continue working as they did before, instead of helping them build powerful data experiences for their users.  We believe that instead of spending hours and hours building out unfulfilling dashboards, data teams should be empowered to build out powerful, self-serve experiences for their users.

Ultimately, we believe that the future of AI analytics is about helping data teams build powerful, self-serve experiences for their users. We think that requires a new approach to the analytics stack.  One that allows for deep integrations between products and allows data teams to truly own their entire experience.

## Roadmap

Currently, we are in the process of open-sourcing the platform.  This includes:

- [Warehouse](/warehouse) ✅
- [BI platform](https://buster.so) ⏰

After that, we will release an official roadmap.

## How We Plan to Make Money

Currently, we offer a few commercial products:

- [Cloud-Hosted Versions](https://buster.so)
  - Warehouse
    - Cluster
    - Serverless
  - BI Platform
- Managed Self-Hosted Version of the Warehouse product.

## Support and feedback

You can contact us through either:

- [Github Discussions](https://github.com/orgs/buster-so/discussions)
- Email us at founders at buster dot com

## License

This repository is MIT licensed, except for the `ee` folders. See [LICENSE](LICENSE) for more details.