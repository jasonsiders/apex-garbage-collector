@SuppressWarnings('PMD.ApexDoc, PMD.AvoidGlobalModifier, PMD.EmptyStatementBlock')
@IsTest
global class GarbageCollectorTestUtils {
	/**
	 * This class contains miscellaneous utilities used to test the Garbage Collector application
	 * - Provides a seam for package subscribers to inject mock GarbageCollector__mdt records for @IsTest purposes.
	 * - Contains utility methods for testing the GarbageCollector application
	 * - Contains a small library of inner classes used for DML mocking, specific to the GarbageCollector application itself.
	 **/
	private GarbageCollectorTestUtils() {
		// Necessary since @IsTest classes cannot also be abstract
	}

	// **** STATIC **** //
	global static List<AsyncApexJob> getBatchJobs() {
		// Note: Even though the Async is technically an inner type, the AsyncApexJob always points to the outer class
		String className = GarbageCollector.class.getName();
		return [SELECT Id FROM AsyncApexJob WHERE ApexClass.Name = :className AND JobType = 'BatchApex'];
	}

	global static void inject(GarbageCollector__mdt mockRecord) {
		// Inject the provided GarbageCollector__mdt record into the test context
		// This is necessary since DML is not supported on custom metadata types.
		GarbageCollectorMetadataSelector.init();
		String name = mockRecord?.DeveloperName;
		GarbageCollectorMetadataSelector.settings?.put(name, mockRecord);
	}

	global static GarbageCollector__mdt initTestSettings(SObjectType objectType) {
		// Generates a simple GarbageCollector__mdt record for the given SObjectType
		// The provided example will delete all records of that SObjectType
		EntityDefinition entity = GarbageCollectorTestUtils.getEntity(Task.SObjectType);
		GarbageCollector__mdt settings = new GarbageCollector__mdt(
			Active__c = true,
			BatchSize__c = 200,
			DeveloperName = objectType?.toString()?.removeEndIgnoreCase('__c') + '_Test',
			HardDelete__c = false,
			QueryWhereClause__c = 'WHERE Id != null',
			SObjectType__c = entity?.Id,
			Type__c = 'Query Based'
		);
		// Mock the parent object details for the SObjectType entity, that would normally be retrieved via SOQL
		Map<String, Object> params = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(settings));
		params?.put('SObjectType__r', entity);
		settings = (GarbageCollector__mdt) JSON.deserialize(JSON.serialize(params), GarbageCollector__mdt.class);
		GarbageCollectorTestUtils.inject(settings);
		return settings;
	}

	// **** PRIVATE **** //
	private static EntityDefinition getEntity(SObjectType objectType) {
		List<EntityDefinition> entities = [
			SELECT Id, QualifiedApiName
			FROM EntityDefinition
			WHERE QualifiedApiName = :objectType.toString()
			LIMIT 1
		];
		return entities?.isEmpty() == false ? entities?.get(0) : null;
	}

	// **** INNER **** //
	public class MockDmlError {
		// Wraps the Database.Error class, to be used for mocking in @IsTest context
		public String message;
		public String statusCode;

		public MockDmlError(System.Exception error) {
			this.message = error?.getMessage();
			this.statusCode = 'TEST_ERROR';
		}
	}

	public class MockDmlResult {
		// This class mocks Database.*Result objects (ex., Database.DeleteResult)
		public List<MockDmlError> errors;
		public Id id;
		public Boolean success;

		public MockDmlResult(Id recordId) {
			this.errors = new List<MockDmlError>();
			this.id = recordId;
			this.success = true;
		}

		public MockDmlResult withError(System.Exception error) {
			MockDmlError dmlError = new MockDmlError(error);
			this.errors?.add(dmlError);
			this.success = false;
			return this;
		}

		public MockDmlResult withError() {
			return this.withError(new System.DmlException());
		}

		public Object toDatabaseResult(Type resultType) {
			return JSON.deserialize(JSON.serialize(this), resultType);
		}
	}
}
