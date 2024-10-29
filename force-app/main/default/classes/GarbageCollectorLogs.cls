@SuppressWarnings('PMD.EmptyStatementBlock')
global abstract class GarbageCollectorLogs {
    private static final GarbageCollectorLogs.Adapter DEFAULT_ADAPTER = new DefaultLogger();

    global static GarbageCollectorLogs.Adapter init() {
        try {   
            // Returns a logger plugin defined in Garbage Collector settings
            // If none defined or invalid, return a default logger which prints to traditional debug logs
            GarbageCollectorSettings__c settings = GarbageCollectorSettings__c.getInstance();
            System.debug('Settings: ' + settings);
            String adapterName = settings?.LogAdapter__c;
            System.debug('Log Adapter Name: ' + adapterName);
            Type adapterType = Type.forName(adapterName);
            System.debug('Log Adapter Type: ' + adapterType);
            return (GarbageCollectorLogs.Adapter) adapterType?.newInstance() ?? DEFAULT_ADAPTER;
        } catch (Exception error) {
            String msg = 'Error generating GarbageCollectorLogs.Adapter plugin: ' + error;
            DEFAULT_ADAPTER?.log(System.LoggingLevel.ERROR, msg);
            return DEFAULT_ADAPTER;
        }
    }

    // **** INNER **** // 
    global interface Adapter {
        // Use this method to register & accumulate log messages in memory
        void log(System.LoggingLevel level, Object message);
        // Use this method to bulk-commit any accumulated logs via DML, if necessary
        void save();
    }

    @TestVisible
    private class DefaultLogger implements GarbageCollectorLogs.Adapter {
        public void log(System.LoggingLevel level, Object message) {
            // Print the message to traditional debug logs
            System.debug(level, message);
        }

        public void save() {
            // No DML required to use the default logger; no-op
        }
    }
}