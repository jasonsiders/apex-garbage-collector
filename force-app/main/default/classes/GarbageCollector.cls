global without sharing virtual class GarbageCollector implements Database.Batchable<SObject> {
    @TestVisible
    private static GarbageCollector.Dml dml = new GarbageCollector.Dml();
    private static final GarbageCollectorLogs.Adapter LOGGER = GarbageCollectorLogs.init();

    public Database.QueryLocator start(Database.BatchableContext context) {
        return null; // TODO!
    }

    public void execute(Database.BatchableContext context, List<SObject> records) {
        // TODO!
    }

    public void finish(Database.BatchableContext context) {
        // TODO!
    }
    
    public virtual Id launch() {
        return null; // TODO!
    }
    
    // **** INNER **** //
    @SuppressWarnings('PMD.ApexSharingViolations')
    @TestVisible
    private virtual class Dml {
        public virtual List<Database.DeleteResult> deleteRecords(List<SObject> records) {
            return Database.delete(records, false, System.AccessLevel.SYSTEM_MODE);
        }

        public virtual List<Database.EmptyRecycleBinResult> emptyRecycleBin(List<SObject> records) {
            return Database.emptyRecycleBin(records);
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
}