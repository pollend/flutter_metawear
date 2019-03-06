/**
 * Variant of the {@link TimeoutException} class that contains a partial result of the task
 * @author Eric Tsai
 */
class TaskTimeoutException implements Exception{
    /** Partial result of the task */
    final Object partial;
    final String message;

    /**
     * Creates an exception with the given message and partial result
     * @param message   Message to accompany the exception
     * @param partial   Partial result of the task
     */
    TaskTimeoutException(this.message,this.partial);

    @override
    String toString() {
        String e = partial.toString();
       return "Task Timeout Exception: $message ($e)";
    }
}
