@SuppressWarnings('PMD.ApexSharingViolations')
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
            return new EmptyQuery()?.getQueryLocator();
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
			return locator ?? new GarbageCollector.EmptyQuery();
		} else {
			return new GarbageCollector.SoqlBasedLocator(this.current);
		}
    }

    private GarbageCollector getNext() {
        // Get the next GarbageCollector__mdt to process
		if (this.current != null) {
			// Remove the current settings record from the map of settings to be processed
			this.pending?.remove(this.current?.DeveloperName);
		}
		LOGGER?.log(System.LoggingLevel.FINEST, 'Pending GarbageCollector__mdt jobs: ' + this.pending?.keySet());
        String nextJobName = (this.pending?.isEmpty() == false) ? this.pending?.values()?.get(0)?.DeveloperName : null;
		this.current = GarbageCollectorMetadataSelector.get(nextJobName);
		LOGGER?.log(System.LoggingLevel.FINEST, 'Next GarbageCollector__mdt job: ' + this.current?.DeveloperName);
		return this;
    }
    
    // **** INNER **** //
    @TestVisible
    private virtual class Dml {
        public virtual List<Database.DeleteResult> deleteRecords(List<SObject> records) {
            return Database.delete(records, false, System.AccessLevel.SYSTEM_MODE);
        }

        public virtual List<Database.EmptyRecycleBinResult> emptyRecycleBin(List<SObject> records) {
            return Database.emptyRecycleBin(records);
        } 
    }

    private class EmptyQuery implements GarbageCollector.QueryLocator {
        // This implementation always returns a completely empty query locator object
        public Database.QueryLocator getQueryLocator() {
            // This query is always performant, and always returns an empty list
            // Only ever one Organization record per environment, and these always have an Id value
            return Database.getQueryLocator([SELECT Id FROM Organization WHERE Id = null]);
        }
    }

    global interface QueryLocator {
        Database.QueryLocator getQueryLocator();
    }

    global class Schedulable implements System.Schedulable {
        public void execute(System.SchedulableContext context) {
			// Kick off the garbage collector job!
			new GarbageCollector()?.launch();
			LOGGER?.save();
		}
    }

    private class SoqlBasedLocator implements GarbageCollector.QueryLocator {
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