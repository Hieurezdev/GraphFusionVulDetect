# Personal data and source code policy

## 1. Personal data collected

| Data | Purpose |
|---|---|
| Email, username | Sign-in, access control |
| Full name (optional) | Shown within the workspace and on review verdicts |
| Sign-in times, actions on code (opening, deleting, role changes) | Audit log for the workspace admin |

Personal data is **not** sent to outside services. An expert reviewer sees the name of whoever asked for a review, not their email.

## 2. Uploaded source code

- Code is stored on the ScanGuard server: the original file and its graphs in the storage folder, the scan results in the database.
- The vulnerability detection models (Slither, CodeBERT, GNN) run entirely on the ScanGuard server.
- **External LLM service:** when the workspace admin allows it, the code of each flagged function (not the whole file) is sent to the LLM service the server is configured with, to write explanations and fix suggestions. When the admin turns it off, these features use a model running on the server, or are switched off.
- A token lookup only sends the token name and the contract address (public data) to CoinGecko and Etherscan.

## 3. Who can see the code

- Members of the workspace, according to their role.
- A ScanGuard reviewer can open a scan only when the workspace allows it and the scan was sent for review.
- Every opening of the source code is recorded in the workspace's audit log.

## 4. Retention and deletion

- Code and scan results are deleted automatically after the retention period set by the admin (30 days by default).
- A user with the right can delete a scan or a project at any time; this removes the files, the results and the knowledge-base items, and scrubs the code from the label log.
- The label log keeps the experts' verdicts (without the code) so that training data stays verifiable.

## 5. Training data

Only when the workspace agrees (see "Use of code as training data").

## 6. User rights

The user can read this text at any time, withdraw the consent to training data, and delete their account. When an account is deleted, its personal data is erased and its name on review verdicts is replaced by a pseudonym.
