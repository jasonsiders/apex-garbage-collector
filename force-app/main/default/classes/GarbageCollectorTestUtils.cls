@SuppressWarnings('PMD.ApexDoc, PMD.AvoidGlobalModifier, PMD.EmptyStatementBlock')
@IsTest 
global class GarbageCollectorTestUtils {
    private GarbageCollectorTestUtils() {
        // Necessary since @IsTest classes cannot also be abstract
    }

    global static void inject(GarbageCollector__mdt mockRecord) {
        GarbageCollectorMetadataSelector.init();
        String name = mockRecord?.DeveloperName;
        GarbageCollectorMetadataSelector.settings?.put(name, mockRecord);
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