# Use of code as training data (optional)

When this option is on for the workspace:

- The code of functions reviewed by experts, with the experts' verdicts and approved fixes, may be used to retrain the models and as reference cases (knowledge base) for later explanations, including for other users.
- A small share of unflagged functions is picked at random for an expert to check, to find vulnerabilities the model missed.

The service works fully without it.

Withdrawing consent: the admin turns the option off in the dashboard. The workspace's code is removed from the knowledge base at once and is not used for later training. A model already trained cannot unlearn what it learned from earlier data.
