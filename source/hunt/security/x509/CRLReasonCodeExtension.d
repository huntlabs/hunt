module hunt.security.x509.CRLReasonCodeExtension;

import hunt.security.cert.CRLReason;
import hunt.security.x509.CertAttrSet;

/**
 * The reasonCode is a non-critical CRL entry extension that identifies
 * the reason for the certificate revocation.
 * @author Hemma Prafullchandra
 * @see java.security.cert.CRLReason
 * @see Extension
 * @see CertAttrSet
 */
// class CRLReasonCodeExtension : Extension, CertAttrSet!String {

//     /**
//      * Attribute name
//      */
//     enum String NAME = "CRLReasonCode";
//     enum String REASON = "reason";

//     private static CRLReason[] values = CRLReason.values();

//     private int reasonCode = 0;

//     private void encodeThis() {
//         if (reasonCode == 0) {
//             this.extensionValue = null;
//             return;
//         }
//         DerOutputStream dos = new DerOutputStream();
//         dos.putEnumerated(reasonCode);
//         this.extensionValue = dos.toByteArray();
//     }

//     /**
//      * Create a CRLReasonCodeExtension with the passed in reason.
//      * Criticality automatically set to false.
//      *
//      * @param reason the enumerated value for the reason code.
//      */
//     this(int reason) {
//         this(false, reason);
//     }

//     /**
//      * Create a CRLReasonCodeExtension with the passed in reason.
//      *
//      * @param critical true if the extension is to be treated as critical.
//      * @param reason the enumerated value for the reason code.
//      */
//     this(boolean critical, int reason)    {
//         this.extensionId = PKIXExtensions.ReasonCode_Id;
//         this.critical = critical;
//         this.reasonCode = reason;
//         encodeThis();
//     }

//     /**
//      * Create the extension from the passed DER encoded value of the same.
//      *
//      * @param critical true if the extension is to be treated as critical.
//      * @param value an array of DER encoded bytes of the actual value.
//      * @exception ClassCastException if value is not an array of bytes
//      * @exception IOException on error.
//      */
//     this(Boolean critical, Object value)
//     {
//         this.extensionId = PKIXExtensions.ReasonCode_Id;
//         this.critical = critical.booleanValue();
//         this.extensionValue = (byte[]) value;
//         DerValue val = new DerValue(this.extensionValue);
//         this.reasonCode = val.getEnumerated();
//     }

//     /**
//      * Set the attribute value.
//      */
//     void set(String name, Object obj) {
//         if (!(obj instanceof Integer)) {
//             throw new IOException("Attribute must be of type Integer.");
//         }
//         if (name.equalsIgnoreCase(REASON)) {
//             reasonCode = ((Integer)obj).intValue();
//         } else {
//             throw new IOException
//                 ("Name not supported by CRLReasonCodeExtension");
//         }
//         encodeThis();
//     }

//     /**
//      * Get the attribute value.
//      */
//     Integer get(String name) {
//         if (name.equalsIgnoreCase(REASON)) {
//             return new Integer(reasonCode);
//         } else {
//             throw new IOException
//                 ("Name not supported by CRLReasonCodeExtension");
//         }
//     }

//     /**
//      * Delete the attribute value.
//      */
//     void delete(String name) {
//         if (name.equalsIgnoreCase(REASON)) {
//             reasonCode = 0;
//         } else {
//             throw new IOException
//                 ("Name not supported by CRLReasonCodeExtension");
//         }
//         encodeThis();
//     }

//     /**
//      * Returns a printable representation of the Reason code.
//      */
//     String toString() {
//         return super.toString() + "    Reason Code: " + getReasonCode();
//     }

//     /**
//      * Write the extension to the DerOutputStream.
//      *
//      * @param out the DerOutputStream to write the extension to.
//      * @exception IOException on encoding errors.
//      */
//     void encode(OutputStream out) {
//         DerOutputStream  tmp = new DerOutputStream();

//         if (this.extensionValue is null) {
//             this.extensionId = PKIXExtensions.ReasonCode_Id;
//             this.critical = false;
//             encodeThis();
//         }
//         super.encode(tmp);
//         out.write(tmp.toByteArray());
//     }

//     /**
//      * Return an enumeration of names of attributes existing within this
//      * attribute.
//      */
//     Enumeration<String> getElements() {
//         AttributeNameEnumeration elements = new AttributeNameEnumeration();
//         elements.addElement(REASON);

//         return elements.elements();
//     }

//     /**
//      * Return the name of this attribute.
//      */
//     String getName() {
//         return NAME;
//     }

//     /**
//      * Return the reason as a CRLReason enum.
//      */
//     CRLReason getReasonCode() {
//         // if out-of-range, return UNSPECIFIED
//         if (reasonCode > 0 && reasonCode < values.length) {
//             return values[reasonCode];
//         } else {
//             return CRLReason.UNSPECIFIED;
//         }
//     }
// }


