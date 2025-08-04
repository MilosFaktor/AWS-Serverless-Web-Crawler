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

Ok, so warning. The filter applies for destination bucket, not for the source bucket of the pull request. A huge warning. Otherwise it seems like everything else is working.

Okay, so the filter, the filter for, I set up a webhook for pull request and it's on create and update of the pull request, because that's all I need, I don't need set closeage, because if there's update or create a new pull request and it just spins up the environment and test it, and then in a filter, branch filter, it didn't work for me a long time and I couldn't resolve what is wrong, and then I came to the official docs of AWS and I was looking that why there is a main branch with asterisks, I tried to put their features slash CI-CD pipeline, and then I realized that there is the destination destination branch that in this case is main, not the source, so it's where the pull request is asking to go, so I fixed that filter and it worked.I also in a CodePipeline, no CodePipeline, in CodeBuild, I passed the environment variable for this one and it's gonna be just, just wrote there environment is dev and then I print it out in a test and it's showing correctly. Just executed a command and correctly. So pipeline is ready for further setup and playing with commands and building build spec YAML.

Perfect now it's correctly changing commit also when the pull request is open and I just push a new commit into the repo and while it's open this update and my code pipeline gets triggered and automatically testing that version that works perfectly.

So I created S3 buckets and I uploaded the source code that I'm going to play with. I created EC2 instance with read access to S3 bucket and maybe I'll need to add there access to CloudFormation or aws sam and I'm going to write build-spec.yaml based on the executions, based on the code that I will use, the EC2 instance.

So I'm testing and writing the built-spec YAML. So far it's looking good.Now I hit the boundary there that I need, it's Python 3.12, for some build, so I'm doing that. But I can define run time at code build, so it will be possible there.

it takes so much time on ec2 instance and i need to set up entire infrastructure so i will run docker locally and test it there. i will also pull image of codebuild and run it locally, so i can test it faster and then push it to the codebuild.


This is great :it  spins up local docketr container with amazonlinux  and deletes after exit. I can test it locally and then push it to the codebuild.
docker run -it --rm \
  -v "$PWD":/workspace \
  -w /workspace \
  amazonlinux:2023 \
  bash



aws/codebuild/amazonlinux-x86_64-standard:5.0
