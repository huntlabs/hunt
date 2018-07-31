module hunt.security.x509.GeneralNameInterface;

import hunt.security.util.DerOutputStream;


/**
 * This interface specifies the abstract methods which have to be
 * implemented by all the members of the GeneralNames ASN.1 object.
 *
 * @author Amit Kapoor
 * @author Hemma Prafullchandra
 */
interface GeneralNameInterface {
    /**
     * The list of names supported.
     */
    enum int NAME_ANY = 0;
    enum int NAME_RFC822 = 1;
    enum int NAME_DNS = 2;
    enum int NAME_X400 = 3;
    enum int NAME_DIRECTORY = 4;
    enum int NAME_EDI = 5;
    enum int NAME_URI = 6;
    enum int NAME_IP = 7;
    enum int NAME_OID = 8;

    /**
     * The list of constraint results.
     */
    enum int NAME_DIFF_TYPE = -1; /* input name is different type from name (i.e. does not constrain) */
    enum int NAME_MATCH = 0;      /* input name matches name */
    enum int NAME_NARROWS = 1;    /* input name narrows name */
    enum int NAME_WIDENS = 2;     /* input name widens name */
    enum int NAME_SAME_TYPE = 3;  /* input name does not match, narrow, or widen, but is same type */

    /**
     * Return the type of the general name, as
     * defined above.
     */
    int getType();

    /**
     * Encode the name to the specified DerOutputStream.
     *
     * @param out the DerOutputStream to encode the GeneralName to.
     * @exception IOException thrown if the GeneralName could not be
     *            encoded.
     */
    void encode(DerOutputStream ot);

    /**
     * Return type of constraint inputName places on this name:<ul>
     *   <li>NAME_DIFF_TYPE = -1: input name is different type from name (i.e. does not constrain).
     *   <li>NAME_MATCH = 0: input name matches name.
     *   <li>NAME_NARROWS = 1: input name narrows name (is lower in the naming subtree)
     *   <li>NAME_WIDENS = 2: input name widens name (is higher in the naming subtree)
     *   <li>NAME_SAME_TYPE = 3: input name does not match or narrow name, but is same type.
     * </ul>.  These results are used in checking NameConstraints during
     * certification path verification.
     *
     * @param inputName to be checked for being constrained
     * @returns constraint type above
     * @throws UnsupportedOperationException if name is same type, but comparison operations are
     *          not supported for this name type.
     */
    int constrains(GeneralNameInterface inputName);

    /**
     * Return subtree depth of this name for purposes of determining
     * NameConstraints minimum and maximum bounds and for calculating
     * path lengths in name subtrees.
     *
     * @returns distance of name from root
     * @throws UnsupportedOperationException if not supported for this name type
     */
    int subtreeDepth();
}
