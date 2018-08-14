module hunt.security.BasicPermission;

import hunt.security.Permission;
import hunt.security.PermissionCollection;

import hunt.container;

import hunt.util.exception;
import hunt.util.string;

import std.algorithm;

/**
 * The BasicPermission class : the Permission class, and
 * can be used as the base class for permissions that want to
 * follow the same naming convention as BasicPermission.
 * <P>
 * The name for a BasicPermission is the name of the given permission
 * (for example, "exit",
 * "setFactory", "print.queueJob", etc). The naming
 * convention follows the  hierarchical property naming convention.
 * An asterisk may appear by itself, or if immediately preceded by a "."
 * may appear at the end of the name, to signify a wildcard match.
 * For example, "*" and "java.*" signify a wildcard match, while "*java", "a*b",
 * and "java*" do not.
 * <P>
 * The action string (inherited from Permission) is unused.
 * Thus, BasicPermission is commonly used as the base class for
 * "named" permissions
 * (ones that contain a name but no actions list; you either have the
 * named permission or you don't.)
 * Subclasses may implement actions on top of BasicPermission,
 * if desired.
 * <p>
 * @see java.security.Permission
 * @see java.security.Permissions
 * @see java.security.PermissionCollection
 * @see java.lang.SecurityManager
 *
 * @author Marianne Mueller
 * @author Roland Schemers
 */

abstract class BasicPermission : Permission
{
    private enum long serialVersionUID = 6279438298436773498L;

    // does this permission have a wildcard at the end?
    private bool wildcard;

    // the name without the wildcard on the end
    private string path;

    // is this permission the old-style exitVM permission (pre JDK 1.6)?
    private bool exitVM;

    /**
     * initialize a BasicPermission object. Common to all constructors.
     */
    private void init(string name) {
        if (name is null)
            throw new NullPointerException("name can't be null");

        int len = cast(int)name.length;

        if (len == 0) {
            throw new IllegalArgumentException("name can't be empty");
        }

        char last = name.charAt(len - 1);

        // Is wildcard or ends with ".*"?
        if (last == '*' && (len == 1 || name.charAt(len - 2) == '.')) {
            wildcard = true;
            if (len == 1) {
                path = "";
            } else {
                path = name.substring(0, len - 1);
            }
        } else {
            if (name.equals("exitVM")) {
                wildcard = true;
                path = "exitVM.";
                exitVM = true;
            } else {
                path = name;
            }
        }
    }

    /**
     * Creates a new BasicPermission with the specified name.
     * Name is the symbolic name of the permission, such as
     * "setFactory",
     * "print.queueJob", or "topLevelWindow", etc.
     *
     * @param name the name of the BasicPermission.
     *
     * @throws NullPointerException if {@code name} is {@code null}.
     * @throws IllegalArgumentException if {@code name} is empty.
     */
    this(string name) {
        super(name);
        init(name);
    }


    /**
     * Creates a new BasicPermission object with the specified name.
     * The name is the symbolic name of the BasicPermission, and the
     * actions string is currently unused.
     *
     * @param name the name of the BasicPermission.
     * @param actions ignored.
     *
     * @throws NullPointerException if {@code name} is {@code null}.
     * @throws IllegalArgumentException if {@code name} is empty.
     */
    this(string name, string actions) {
        super(name);
        init(name);
    }

    /**
     * Checks if the specified permission is "implied" by
     * this object.
     * <P>
     * More specifically, this method returns true if:
     * <ul>
     * <li> <i>p</i>'s class is the same as this object's class, and
     * <li> <i>p</i>'s name equals or (in the case of wildcards)
     *      is implied by this object's
     *      name. For example, "a.b.*" implies "a.b.c".
     * </ul>
     *
     * @param p the permission to check against.
     *
     * @return true if the passed permission is equal to or
     * implied by this permission, false otherwise.
     */
    override bool implies(Permission p) {
        if ((p is null) || (typeid(p) != typeid(this)))
            return false;

        BasicPermission that = cast(BasicPermission) p;

        if (this.wildcard) {
            if (that.wildcard) {
                // one wildcard can imply another
                return that.path.startsWith(path);
            } else {
                // make sure ap.path is longer so a.b.* doesn't imply a.b
                return (that.path.length > this.path.length) &&
                    that.path.startsWith(this.path);
            }
        } else {
            if (that.wildcard) {
                // a non-wildcard can't imply a wildcard
                return false;
            }
            else {
                return this.path.equals(that.path);
            }
        }
    }

    /**
     * Checks two BasicPermission objects for equality.
     * Checks that <i>obj</i>'s class is the same as this object's class
     * and has the same name as this object.
     * <P>
     * @param obj the object we are testing for equality with this object.
     * @return true if <i>obj</i>'s class is the same as this object's class
     *  and has the same name as this BasicPermission object, false otherwise.
     */
    override
    bool opEquals(Object obj) {
        if (obj == this)
            return true;

        if ((obj is null) || (typeid(obj) != typeid(this)))
            return false;

        BasicPermission bp = cast(BasicPermission) obj;

        return getName().equals(bp.getName());
    }


    /**
     * Returns the hash code value for this object.
     * The hash code used is the hash code of the name, that is,
     * {@code getName().hashCode()}, where {@code getName} is
     * from the Permission superclass.
     *
     * @return a hash code value for this object.
     */
    override size_t toHash() @trusted nothrow {
        return hashOf(this.getName());
    }

    /**
     * Returns the canonical string representation of the actions,
     * which currently is the empty string "", since there are no actions for
     * a BasicPermission.
     *
     * @return the empty string "".
     */
    override string getActions() {
        return "";
    }

    /**
     * Returns a new PermissionCollection object for storing BasicPermission
     * objects.
     *
     * <p>BasicPermission objects must be stored in a manner that allows them
     * to be inserted in any order, but that also enables the
     * PermissionCollection {@code implies} method
     * to be implemented in an efficient (and consistent) manner.
     *
     * @return a new PermissionCollection object suitable for
     * storing BasicPermissions.
     */
    override PermissionCollection newPermissionCollection() {
        // return new BasicPermissionCollection(this.getClass());
        return new BasicPermissionCollection(this);
    }

    /**
     * readObject is called to restore the state of the BasicPermission from
     * a stream.
     */
    // private void readObject(ObjectInputStream s)
    // {
    //     s.defaultReadObject();
    //     // init is called to initialize the rest of the values.
    //     init(getName());
    // }

    /**
     * Returns the canonical name of this BasicPermission.
     * All internal invocations of getName should invoke this method, so
     * that the pre-JDK 1.6 "exitVM" and current "exitVM.*" permission are
     * equivalent in equals/hashCode methods.
     *
     * @return the canonical name of this BasicPermission.
     */
    final string getCanonicalName() {
        return exitVM ? "exitVM.*" : getName();
    }
}

/**
 * A BasicPermissionCollection stores a collection
 * of BasicPermission permissions. BasicPermission objects
 * must be stored in a manner that allows them to be inserted in any
 * order, but enable the implies function to evaluate the implies
 * method in an efficient (and consistent) manner.
 *
 * A BasicPermissionCollection handles comparing a permission like "a.b.c.d.e"
 * with a Permission such as "a.b.*", or "*".
 *
 * @see java.security.Permission
 * @see java.security.Permissions
 *
 *
 * @author Roland Schemers
 *
 * @serial include
 */

final class BasicPermissionCollection : PermissionCollection
{

    private enum long serialVersionUID = 739301742472979399L;

    /**
      * Key is name, value is permission. All permission objects in
      * collection must be of the same type.
      * Not serialized; see serialization section at end of class.
      */
    private Map!(string, Permission) perms;

    /**
     * This is set to {@code true} if this BasicPermissionCollection
     * contains a BasicPermission with '*' as its permission name.
     *
     * @see #serialPersistentFields
     */
    private bool all_allowed;

    /**
     * The class to which all BasicPermissions in this
     * BasicPermissionCollection belongs.
     *
     * @see #serialPersistentFields
     */
    // private Class<?> permClass;

    /**
     * Create an empty BasicPermissionCollection object.
     *
     */

    // this(Class<?> clazz) {
    this(Object clazz) {
        perms = new HashMap!(string, Permission)(11);
        all_allowed = false;
        // permClass = clazz;
    }

    /**
     * Adds a permission to the BasicPermissions. The key for the hash is
     * permission.path.
     *
     * @param permission the Permission object to add.
     *
     * @exception IllegalArgumentException - if the permission is not a
     *                                       BasicPermission, or if
     *                                       the permission is not of the
     *                                       same Class as the other
     *                                       permissions in this collection.
     *
     * @exception SecurityException - if this BasicPermissionCollection object
     *                                has been marked readonly
     */
    override void add(Permission permission) {
        implementationMissing();
        // if (! (permission instanceof BasicPermission))
        //     throw new IllegalArgumentException("invalid permission: "~
        //                                        permission.toString());
        // if (isReadOnly())
        //     throw new SecurityException("attempt to add a Permission to a readonly PermissionCollection");

        // // BasicPermission bp = (BasicPermission) permission;

        // // make sure we only add new BasicPermissions of the same class
        // // Also check null for compatibility with deserialized form from
        // // previous versions.
        // // if (permClass is null) {
        // //     // adding first permission
        // //     permClass = bp.getClass();
        // // } else {
        // //     if (bp.getClass() != permClass)
        // //         throw new IllegalArgumentException("invalid permission: " ~
        // //                                         permission);
        // }

        // synchronized (this) {
        //     perms.put(bp.getCanonicalName(), permission);
        // }

        // // No sync on all_allowed; staleness OK
        // if (!all_allowed) {
        //     if (bp.getCanonicalName().equals("*"))
        //         all_allowed = true;
        // }
    }

    /**
     * Check and see if this set of permissions implies the permissions
     * expressed in "permission".
     *
     * @param permission the Permission object to compare
     *
     * @return true if "permission" is a proper subset of a permission in
     * the set, false if not.
     */
    override bool implies(Permission permission) {
        if (typeid(permission) !=  typeid(BasicPermission))
            return false;

        implementationMissing();

        // BasicPermission bp = cast(BasicPermission) permission;

        // // random subclasses of BasicPermission do not imply each other
        // if (bp.getClass() != permClass)
        //     return false;

        // // short circuit if the "*" Permission was added
        // if (all_allowed)
        //     return true;

        // // strategy:
        // // Check for full match first. Then work our way up the
        // // path looking for matches on a.b..*

        // string path = bp.getCanonicalName();
        // //System.out.println("check "+path);

        // Permission x;

        // synchronized (this) {
        //     x = perms.get(path);
        // }

        // if (x !is null) {
        //     // we have a direct hit!
        //     return x.implies(permission);
        // }

        // // work our way up the tree...
        // int last, offset;

        // offset = path.length-1;

        // while ((last = path.lastIndexOf(".", offset)) != -1) {

        //     path = path.substring(0, last+1) ~ "*";
        //     //System.out.println("check "+path);

        //     synchronized (this) {
        //         x = perms.get(path);
        //     }

        //     if (x !is null) {
        //         return x.implies(permission);
        //     }
        //     offset = last -1;
        // }

        // we don't have to check for "*" as it was already checked
        // at the top (all_allowed), so we just return false
        return false;
    }

    /**
     * Returns an enumeration of all the BasicPermission objects in the
     * container.
     *
     * @return an enumeration of all the BasicPermission objects.
     */
    override Enumeration!Permission elements() {
        // Convert Iterator of Map values into an Enumeration
        synchronized (this) {
            return Collections.enumeration(perms.values());
        }
    }

    // Need to maintain serialization interoperability with earlier releases,
    // which had the serializable field:
    //
    // @serial the Hashtable is indexed by the BasicPermission name
    //
    // private Hashtable permissions;
    /**
     * @serialField permissions java.util.Hashtable
     *    The BasicPermissions in this BasicPermissionCollection.
     *    All BasicPermissions in the collection must belong to the same class.
     *    The Hashtable is indexed by the BasicPermission name; the value
     *    of the Hashtable entry is the permission.
     * @serialField all_allowed bool
     *   This is set to {@code true} if this BasicPermissionCollection
     *   contains a BasicPermission with '*' as its permission name.
     * @serialField permClass java.lang.Class
     *   The class to which all BasicPermissions in this
     *   BasicPermissionCollection belongs.
     */
    // private static final ObjectStreamField[] serialPersistentFields = {
    //     new ObjectStreamField("permissions", Hashtable.class),
    //     new ObjectStreamField("all_allowed", Boolean.TYPE),
    //     new ObjectStreamField("permClass", Class.class),
    // };

    // /**
    //  * @serialData Default fields.
    //  */
    // /*
    //  * Writes the contents of the perms field out as a Hashtable for
    //  * serialization compatibility with earlier releases. all_allowed
    //  * and permClass unchanged.
    //  */
    // private void writeObject(ObjectOutputStream out) {
    //     // Don't call out.defaultWriteObject()

    //     // Copy perms into a Hashtable
    //     Hashtable!(string, Permission) permissions =
    //             new Hashtable<>(perms.size()*2);

    //     synchronized (this) {
    //         permissions.putAll(perms);
    //     }

    //     // Write out serializable fields
    //     ObjectOutputStream.PutField pfields = out.putFields();
    //     pfields.put("all_allowed", all_allowed);
    //     pfields.put("permissions", permissions);
    //     pfields.put("permClass", permClass);
    //     out.writeFields();
    // }

    // /**
    //  * readObject is called to restore the state of the
    //  * BasicPermissionCollection from a stream.
    //  */
    // private void readObject(java.io.ObjectInputStream in)
    //     , ClassNotFoundException
    // {
    //     // Don't call defaultReadObject()

    //     // Read in serialized fields
    //     ObjectInputStream.GetField gfields = in.readFields();

    //     // Get permissions
    //     // writeObject writes a Hashtable!(string, Permission) for the
    //     // permissions key, so this cast is safe, unless the data is corrupt.
    //     @SuppressWarnings("unchecked")
    //     Hashtable!(string, Permission) permissions =
    //             (Hashtable!(string, Permission))gfields.get("permissions", null);
    //     perms = new HashMap!(string, Permission)(permissions.size()*2);
    //     perms.putAll(permissions);

    //     // Get all_allowed
    //     all_allowed = gfields.get("all_allowed", false);

    //     // Get permClass
    //     permClass = (Class<?>) gfields.get("permClass", null);

    //     if (permClass is null) {
    //         // set permClass
    //         Enumeration<Permission> e = permissions.elements();
    //         if (e.hasMoreElements()) {
    //             Permission p = e.nextElement();
    //             permClass = p.getClass();
    //         }
    //     }
    // }
}