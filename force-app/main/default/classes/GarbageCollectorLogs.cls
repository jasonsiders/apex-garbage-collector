@SuppressWarnings('PMD.ApexDoc, PMD.AvoidDebugStatements, PMD.AvoidGlobalModifier, PMD.EmptyStatementBlock')
global abstract class GarbageCollectorLogs {
	/**
	 * This class provides a plugin interface for logging within the GarbageCollector application.
	 * Callers can optionally create their own implementation of the `GarbageCollectorLogs.Adapter` interface,
	 * and point to this implenentation in the GarbageCollectorSettings__c custom setting type
	 * If no plugin is defined, logs are committed to traditional Salesforce debug logs by default.
	 **/
	private static final GarbageCollectorLogs.Adapter DEFAULT_ADAPTER = new DefaultLogger();

	global static GarbageCollectorLogs.Adapter init() {
		try {
			// Returns a logger plugin defined in Garbage Collector settings
			// If none defined or invalid, return a default logger which prints to traditional debug logs
			Type loggerPlugin = Type.forName(GarbageCollectorSettings__c.getInstance()?.LogAdapter__c);
			return (GarbageCollectorLogs.Adapter) loggerPlugin?.newInstance() ?? DEFAULT_ADAPTER;
		} catch (Exception error) {
			String msg = 'Could not initialize GarbageCollectorLogs.Adapter: ' + error;
			DEFAULT_ADAPTER?.log(System.LoggingLevel.WARN, msg);
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
