### Do you want to see all screenshots from the project?  
👉 [All screenshots](docs/screenshots/)

### Want the full build journey with errors, fixes, lessons, and AWS tweaks?  
👉 [BUILD-JOURNAL.md](docs/BUILD-JOURNAL.md)

Notes: 


## Screenshots

<img src="docs/screenshots/6 - SAM deployed resources.png" width="750">

<img src="docs/screenshots/7 - CloudFromation stack created.png" width="750"> 

<img src="docs/screenshots/10 - Initiator.png" width="750">

<img src="docs/screenshots/11 - Crawler.png" width="750">

<img src="docs/screenshots/8 - dynamoDB after crawl.png" width="750">

<img src="docs/screenshots/9 - CloudWatch metrics.png" width="750">

---

## 👤 Author
Milos Faktor — [LinkedIn](https://www.linkedin.com/in/milos-faktor-78b429255/)

Built and tested in Denmark, shared with the world.

---

### Want the full build journey with errors, fixes, lessons, and AWS tweaks?  
👉 [BUILD-JOURNAL.md](docs/BUILD-JOURNAL.md)

### Do you want to see all screenshots from the project?  
👉 [All screenshots](docs/screenshots/)



Notes: 

I’ve been thinking through the CI/CD pipeline setup for my serverless WebCrawler project, and here’s the plan I’m leaning toward:

When I open a pull request, it’ll trigger a CodeBuild job that deploys the whole stack to a dev environment using AWS SAM (with a separate stack name).

In that dev setup, it’ll run some basic tests — like invoking a Lambda or checking that a response comes back OK.

If the tests pass, I’ll submit it for review (like you mentioned with reviewers).

After it’s approved and merged into main, it’ll deploy to production — potentially using something like canary or linear rollout later on.

codepipeline source ,connection via github app ,so a repository name and default branch is main, but then in a webhook events I specified event type pull request, events for pull request. It's when pull request is created and then start pipeline under these conditions, filter type branches or patterns and I input it feature slash asterisks and then file paths. I don't need file paths so for now.

I created source source and I connected github with a github app and on a pull request in feature slash asterisk will trigger the pipeline and then second one I added the code build and the code build is just just as the build spec the demo is going to be used there and this is a development environmentBut I need to create it separately and then connect it to, I mean the code deploy, no, code build I need to create separately and then put it in, put it into, connect it into the pipeline. So that's it so far,

I also created ddefault IAM roles there, but I know there's from previous exercises I did on the CI-CD pipeline there's gonna be some problems, so I'll modify it later. But, okay, I'm going to test, I'm going to do some PR for requests.

Okay, so I created a new branch. It just features my CICD underscore trigger underscore test, and I modified readme file. I pushed it, and now I'm going to now I'm going to my, I'm going to my github and make a pull request.

new