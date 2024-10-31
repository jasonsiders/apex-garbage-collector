@SuppressWarnings('PMD.ApexDoc, PMD.ApexSharingViolations, PMD.AvoidGlobalModifier')
global without sharing virtual class GarbageCollector implements Database.Batchable<SObject> {
    // **** STATIC **** //
    @TestVisible
    private static GarbageCollector.Dml dml = new GarbageCollector.Dml();
    private static final Integer DEFAULT_BATCH_SIZE = 200;
    private static final GarbageCollectorLogs.Adapter LOGGER = GarbageCollectorLogs.init();

    // **** MEMBER **** //
    private GarbageCollector__mdt current;
    private Map<String, GarbageCollector__mdt> pending;
    private transient String logPrefix { 
        get {
            return this.current?.DeveloperName + ': ';
        }
    }

    public GarbageCollector() {
        this.pending = GarbageCollectorMetadataSelector.getAll();
        this.getNext();
    }

    public Database.QueryLocator start(Database.BatchableContext context) {
        try {
            return this.initLocator()?.getQueryLocator();
        } catch (Exception error) {
            LOGGER?.log(System.LoggingLevel.ERROR, this.logPrefix + 'Could not retrieve records:\n' + error);
            return new EmptyQueryLocator()?.getQueryLocator();
        } finally {
            LOGGER?.save();
        }
    }

    public void execute(Database.BatchableContext context, List<SObject> records) {
        try {
			LOGGER?.log(System.LoggingLevel.FINEST, this.logPrefix + 'Deleting ' + records?.size() + ' records');
			GarbageCollector.dml?.deleteRecords(records);
			// Optionally hard delete the records, if configured to do so
			if (this.current?.HardDelete__c == true) {
				LOGGER?.log(System.LoggingLevel.FINEST, this.logPrefix + 'Emptying recycle bin');
				GarbageCollector.dml?.emptyRecycleBin(records);
			}
		} catch (Exception error) {
			LOGGER?.log(System.LoggingLevel.ERROR, error);
		} finally {
			LOGGER?.save();
		}
    }

    public void finish(Database.BatchableContext context) {
        // Launch the next job in the chain
		try {
			LOGGER?.log(System.LoggingLevel.FINEST, this.logPrefix + 'Finished!');
			this.getNext()?.launch();
		} catch (Exception error) {
			LOGGER?.log(System.LoggingLevel.ERROR, error);
		} finally {
			LOGGER?.save();
		}
    }
    
    public virtual Id launch() {
        if (this.current != null) {
            Integer batchSize = this.current?.BatchSize__c?.intValue() ?? DEFAULT_BATCH_SIZE;
            Id jobId = Database.executeBatch(this, batchSize);
            LOGGER?.log(System.LoggingLevel.INFO, this.logPrefix + 'Launching new job: ' + jobId);
            return jobId;
        } else {
            return null;
        }
    }

    private GarbageCollector.QueryLocator initLocator() {
        if (this.current?.Type__c == 'Apex Based') {
			Type locatorClass = Type.forName(this.current?.ApexClassName__c);
			GarbageCollector.QueryLocator locator = (GarbageCollector.QueryLocator) locatorClass?.newInstance();
			return locator ?? new GarbageCollector.EmptyQueryLocator();
		} else {
			return new GarbageCollector.SoqlBasedLocator(this.current);
		}
    }

    private GarbageCollector getNext() {
        // Get the next GarbageCollector__mdt to process
        String jobName = (this.pending?.isEmpty() == false) ? this.pending?.values()?.get(0)?.DeveloperName : null;
		this.current = GarbageCollectorMetadataSelector.get(jobName);
        // Remove the current job from the list of pending jobs
        this.pending?.remove(jobName);
        // Validate that the job's settings record is still active
        if (this.current?.Active__c == false) {
            // If so, skip the current job, and recurse to find the next job in the chain
            LOGGER?.log(System.LoggingLevel.FINEST, this.logPrefix + 'Skipping inactive job');
            this.getNext();
        }
        LOGGER?.log(System.LoggingLevel.FINEST, 'Next GarbageCollector__mdt job: ' + this.current?.DeveloperName);
        LOGGER?.log(System.LoggingLevel.FINEST, 'Pending GarbageCollector__mdt jobs: ' + this.pending?.keySet());
		return this;
    }
    
    // **** INNER **** //
    @TestVisible
    private virtual class Dml {
        // This small utility class is responsible for processing DML for the Garbage Collector
        // Normally, this would be delegated to an external utility, 
        // but is included here to encapsulate the Garbage Collector application
        public virtual List<Database.DeleteResult> deleteRecords(List<SObject> records) {
            return Database.delete(records, false, System.AccessLevel.SYSTEM_MODE);
        }

        public virtual List<Database.EmptyRecycleBinResult> emptyRecycleBin(List<SObject> records) {
            return Database.emptyRecycleBin(records);
        } 
    }

    private class EmptyQueryLocator implements GarbageCollector.QueryLocator {
        // This implementation always returns a completely empty query locator object
        public Database.QueryLocator getQueryLocator() {
            // This query is always performant, and always returns an empty list
            // Only ever one Organization record per environment, and these always have an Id value
            return Database.getQueryLocator([SELECT Id FROM Organization WHERE Id = null]);
        }
    }

    global interface QueryLocator {
        // Implement this interface to define custom logic that identifies records to be deleted.
        // For use in conjunction with "Apex Based" GarbageCollector__mdt jobs.
        // NOTE: In addition to implementing the method below, you will also need a public 0-arg constructor.
        Database.QueryLocator getQueryLocator();
    }

    global class Schedulable implements System.Schedulable {
        // Allows the Garbage Collector job to be run on a regular schedule
        global void execute(System.SchedulableContext context) {
			new GarbageCollector()?.launch();
			LOGGER?.save();
		}
    }

    private class SoqlBasedLocator implements GarbageCollector.QueryLocator {
        // This implementation constructs a SOQL query based on the GarbageCollector__mdt configuration
        private GarbageCollector__mdt settings;

		private SoqlBasedLocator(GarbageCollector__mdt settings) {
			this.settings = settings;
		}

		public Database.QueryLocator getQueryLocator() {
			String query = this.toString();
			LOGGER?.log(System.LoggingLevel.FINEST, SoqlBasedLocator.class + ' [' + this.settings?.DeveloperName + ']\nQuery: ' + query);
			return Database.getQueryLocator(query, System.AccessLevel.SYSTEM_MODE);
		}

		public override String toString() {
			String template = 'SELECT Id FROM {0} WHERE {1}';
			String fromObject = this.settings?.SObjectType__r?.QualifiedApiName;
			String whereClause = this.getWhereClause();
			return String.format(template, new List<String>{ fromObject, whereClause });
		}

		private String getWhereClause() {
			return this.settings?.QueryWhereClause__c?.removeStartIgnoreCase('WHERE ')?.trim();
		}
    }
}