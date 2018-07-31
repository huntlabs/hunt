module hunt.security.Principal;

import hunt.security.Subject;

/**
 * This interface represents the abstract notion of a principal, which
 * can be used to represent any entity, such as an individual, a
 * corporation, and a login id.
 *
 * @see java.security.cert.X509Certificate
 */
interface Principal {

    /**
     * Compares this principal to the specified object.  Returns true
     * if the object passed in matches the principal represented by
     * the implementation of this interface.
     *
     * @param another principal to compare with.
     *
     * @return true if the principal passed in is the same as that
     * encapsulated by this principal, and false otherwise.
     */
    bool opEquals(Object another);

    /**
     * Returns a string representation of this principal.
     *
     * @return a string representation of this principal.
     */
    string toString();

    /**
     * Returns a hashcode for this principal.
     *
     * @return a hashcode for this principal.
     */
    // int toHash();
    size_t toHash() @trusted nothrow;

    /**
     * Returns the name of this principal.
     *
     * @return the name of this principal.
     */
    string getName();

    /**
     * Returns true if the specified subject is implied by this principal.
     *
     * <p>The default implementation of this method returns true if
     * {@code subject} is non-null and contains at least one principal that
     * is equal to this principal.
     *
     * <p>Subclasses may override this with a different implementation, if
     * necessary.
     *
     * @param subject the {@code Subject}
     * @return true if {@code subject} is non-null and is
     *              implied by this principal, or false otherwise.
     * @since 1.8
     */
    // bool implies(Subject subject);
    // {
    //     if (subject == null)
    //         return false;
    //     return subject.getPrincipals().contains(this);
    // }
}