# The Future

## Next Investments

### 0. The cutover plan.
This happens before the cutover happens. "If you fail to plan, you plan to fail." For real, this is like.. the actual very next thing that needs to happen.

### 1. Human access to the AWS accounts.
This happens before the cutover happens, and honestly probably part as handing over this entire project to the Acme Corp team. We need to establish a pattern of accessing the AWS accounts, and make sure that it is easy and understandable for the folks who need to access these accounts, otherwise we end up with long-lived IAM credentials getting shared in Slack. 🙃

### 2. CI/CD via GitHub Actions (GHA).
This needs to be implemented before cutover to this infrastructure is completed — I consider this a fairly essential piece of the puzzle. It ensures the utmost repeatability of our deployments, centralizes the logging of said deployments (rather than the outputs being scattered hither and yon across team members' computers), and also reduces burden on the engineering team.

### 3. Alerting.
Alerting and general observability need to be implemented as soon as we are cut over to the new infrastructure. We already have logs and container insights set up, so the data is being gathered in CloudWatch — we just need to set up some alerts. It's important to have some data from the apps existing in this new infrastructure prior to setting up alerts, otherwise we're setting things up blindly, and potentially alerting on non-issues (which can lead to "the boy who cried wolf" type scenarios, alert fatigue, etc.).

### 4. Auto-scaling.
The first time after cutover that our customers experience reliability issues with our product, we should start building and shaping an auto-scaling plan. We just need that first data point to start hypothesizing what that auto-scaling plan should look like.


## Likely Pain Points

As Acme Corp grows, I expect the likely pain points in this architecture to be:

* RDS connection exhaustion (we've opted for pretty tiny RDS instance types that have low default `max_conection` values)
* lack of application auto-scaling (if not addressed upon first incidence of reliability issues)
* the singular NAT gateway (every outbound call from every private subnet task funnels through one NAT gateway)