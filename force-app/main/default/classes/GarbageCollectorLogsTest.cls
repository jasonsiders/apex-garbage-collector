@IsTest 
public class GarbageCollectorLogsTest {
    // **** CONSTANTS **** //
    private static final Type DEFAULT_ADAPTER_TYPE = GarbageCollectorLogs.DefaultLogger.class;

    // **** TESTS **** //
    @IsTest 
    static void shouldUseProvidedAdapter() {
        Type adapterType = GarbageCollectorLogsTest.TestAdapter.class;
        GarbageCollectorSettings__c settings = new GarbageCollectorSettings__c(
            LogAdapter__c = adapterType?.getName(),
            Name = 'Test'
        ); 
        insert settings;


        Test.startTest();
        GarbageCollectorLogs.Adapter adapter = GarbageCollectorLogs.init();
        Test.stopTest();

        Assert.areNotEqual(null, adapter, 'Returned null GarbageCollectorLogs.Adapter');
        Assert.isInstanceOfType(adapter, adapterType, 'Wrong type of GarbageCollectorLogs.Adapter');
    }

    @IsTest 
    static void shouldUseDefaultLoggerIfSpecified() {
        GarbageCollectorSettings__c settings = new GarbageCollectorSettings__c(
            LogAdapter__c = DEFAULT_ADAPTER_TYPE?.getName(),
            Name = 'Test'
        ); 
        insert settings;

        Test.startTest();
        GarbageCollectorLogs.Adapter adapter = GarbageCollectorLogs.init();
        Test.stopTest();

        Assert.areNotEqual(null, adapter, 'Returned null GarbageCollectorLogs.Adapter');
        Assert.isInstanceOfType(adapter, DEFAULT_ADAPTER_TYPE, 'Wrong type of GarbageCollectorLogs.Adapter');
    }

    @IsTest 
    static void shouldUseDefaultLoggerIfNoSettingsDefined() {
        Test.startTest();
        GarbageCollectorLogs.Adapter adapter = GarbageCollectorLogs.init();
        Test.stopTest();

        Assert.areNotEqual(null, adapter, 'Returned null GarbageCollectorLogs.Adapter');
        Assert.isInstanceOfType(adapter, DEFAULT_ADAPTER_TYPE, 'Wrong type of GarbageCollectorLogs.Adapter');
    }

    @IsTest 
    static void shouldUseDefaultLoggerIfNoLogAdapterDefined() {
        GarbageCollectorSettings__c settings = new GarbageCollectorSettings__c(Name = 'Test');
        insert settings;

        Test.startTest();
        GarbageCollectorLogs.Adapter adapter = GarbageCollectorLogs.init();
        Test.stopTest();

        Assert.areNotEqual(null, adapter, 'Returned null GarbageCollectorLogs.Adapter');
        Assert.isInstanceOfType(adapter, DEFAULT_ADAPTER_TYPE, 'Wrong type of GarbageCollectorLogs.Adapter');
    }

    @IsTest 
    static void shouldUseDefaultLoggerIfInvalidLogAdapter() {
        GarbageCollectorSettings__c settings = new GarbageCollectorSettings__c(
            LogAdapter__c = 'abcd1234', // Not a real log adapter!
            Name = 'Test'
        );
        insert settings;

        Test.startTest();
        GarbageCollectorLogs.Adapter adapter = GarbageCollectorLogs.init();
        Test.stopTest();

        Assert.areNotEqual(null, adapter, 'Returned null GarbageCollectorLogs.Adapter');
        Assert.isInstanceOfType(adapter, DEFAULT_ADAPTER_TYPE, 'Wrong type of GarbageCollectorLogs.Adapter');
    }

    @IsTest 
    static void shouldUseDefaultLoggingBehavior() {
        // This method is mostly for coverage, since we can't check/assert standard System.debug behavior
        GarbageCollectorLogs.Adapter logger = new GarbageCollectorLogs.DefaultLogger();

        Test.startTest();
        try {
            logger?.log(System.LoggingLevel.INFO, 'This is a test!');
            logger?.save();
        } catch (Exception error) {
            Assert.fail('Failed to log: ' + error); 
        }
        Test.stopTest();
    }

    // **** SETUP **** // 
    @TestSetup 
    static void setup() {
        delete [SELECT Id FROM GarbageCollectorSettings__c];
    }

    // **** INNER **** // 
    @SuppressWarnings('PMD.EmptyStatementBlock')
    public class TestAdapter implements GarbageCollectorLogs.Adapter {
        public void log(System.LoggingLevel level, Object message) {
            // This test adapter doesn't need to do anything
        }

        public void save() {
            // This test adapter doesn't need to do anything
        }
    }
}