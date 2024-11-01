@SuppressWarnings('PMD.ApexDoc, PMD.AvoidEmptyBlockStatements, PMD.AvoidGlobalModifier')
global class GarbageCollectorSchedulable implements System.Schedulable {
	/**
	 * Allows the GarbageCollector logic to be run on a regularly scheduled basis
	 * Use this class in conjunction with standard scheduled apex functionality
	 **/
	private static final GarbageCollectorLogs.Adapter LOGGER = GarbageCollectorLogs.init();

	global void execute(System.SchedulableContext context) {
		new GarbageCollector()?.launch();
		LOGGER?.save();
	}
}
