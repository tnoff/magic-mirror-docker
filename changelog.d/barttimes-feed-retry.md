Bumped MMM-BartTimes to 5a9fb0d — a transient 5xx from the transit feed is now retried instead of blanking the departure board until the next refresh
Bumped MMM-BartTimes tracing — each feed fetch is one span statused on its final outcome, so a failure a retry recovered from no longer shows as an error in traces
