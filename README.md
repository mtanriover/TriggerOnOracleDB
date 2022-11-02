# TriggerSampleOnOracleDB
When you make a debt payment to your service provider, if your service has been terminated due to your debt, it is an example of a trigger that completes the software process necessary for you to receive service again in return for the payment you made. This trigger, which I developed, is now actively used in all payment channels of a municipal water utility. Table names and field names have been changed for confidentiality reasons.

Step 1: trigger is logging (on a log table) when made payment.

Step 2: Job is runs a procedure every 5 minutes.

Step 3: Procedure is checks for is there any overdue debt that member's (on log table), procedure creates work order if there is no overdue debt 
