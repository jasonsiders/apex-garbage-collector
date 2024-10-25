public without sharing abstract class GarbageCollectorMetadataSelector {
	@TestVisible
	private static Map<String, GarbageCollector__mdt> settings;

	public static Map<String, GarbageCollector__mdt> getAll() {
        // Retrieve all garbage collector records, mapped by their Developer Names
        GarbageCollectorMetadataSelector.init();
		return settings;
	}

    public static GarbageCollector__mdt get(String developerName) {
        // Retrieve a single Garbage Collector record by its Developer Name
        GarbageCollectorMetadataSelector.init();
        return settings?.get(developerName);
    }

    // **** PRIVATE **** //
    @TestVisible
    private static void init() {
        // Lazily-initialization; query & Map metadata if it hasn't already been done this transaction
        settings = settings ?? GarbageCollectorMetadataSelector.retrieveFromDatabase();
    }

    @TestVisible
    static Map<String, GarbageCollector__mdt> mapByDeveloperName(List<GarbageCollector__mdt> records) {
        // Map the provided list of metadata records by their developer name
        Map<String, GarbageCollector__mdt> recordMap = new Map<String, GarbageCollector__mdt>();
        for (GarbageCollector__mdt record : records) {
			String developerName = record?.DeveloperName;
			recordMap?.put(developerName, record);
		}
		return recordMap;
    }

    static List<GarbageCollector__mdt> queryRecords() {
        // Retrieve all garbage collector records in the org via SOQL
        // * Note: Normally, we'd use GarbageCollector__mdt.getAll() to save a SOQL query
        // * However, that method does not support relationship fields (ie., SObjectType__r.QualifiedApiName)
        // * or long text area fields (ie., QueryWhereClause__c)
        return [
			SELECT
				Id,
				Active__c,
				ApexClassName__c,
				BatchSize__c,
				DeveloperName,
				HardDelete__c,
				QueryWhereClause__c,
				SObjectType__r.QualifiedApiName,
				Type__c
			FROM GarbageCollector__mdt
            WITH SYSTEM_MODE
		];
    }

    private static Map<String, GarbageCollector__mdt> retrieveFromDatabase() {
        // Query for any Garbage Collector records, and map them by their Developer Names
		List<GarbageCollector__mdt> records = GarbageCollectorMetadataSelector.queryRecords();
        return GarbageCollectorMetadataSelector.mapByDeveloperName(records);
	}
}
