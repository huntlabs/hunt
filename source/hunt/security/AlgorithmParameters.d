module hunt.security.AlgorithmParameters;

import hunt.security.spec.AlgorithmParameterSpec;
import hunt.security.Provider;

import hunt.util.exception;

import std.array;

/**
 * This class defines the <i>Service Provider Interface</i> (<b>SPI</b>)
 * for the {@code AlgorithmParameters} class, which is used to manage
 * algorithm parameters.
 *
 * <p> All the abstract methods in this class must be implemented by each
 * cryptographic service provider who wishes to supply parameter management
 * for a particular algorithm.
 *
 * @author Jan Luehe
 *
 *
 * @see AlgorithmParameters
 * @see java.security.spec.AlgorithmParameterSpec
 * @see java.security.spec.DSAParameterSpec
 *
 * @since 1.2
 */

abstract class AlgorithmParametersSpi {

    /**
     * Initializes this parameters object using the parameters
     * specified in {@code paramSpec}.
     *
     * @param paramSpec the parameter specification.
     *
     * @exception InvalidParameterSpecException if the given parameter
     * specification is inappropriate for the initialization of this parameter
     * object.
     */
    protected abstract void engineInit(AlgorithmParameterSpec paramSpec);

    /**
     * Imports the specified parameters and decodes them
     * according to the primary decoding format for parameters.
     * The primary decoding format for parameters is ASN.1, if an ASN.1
     * specification for this type of parameters exists.
     *
     * @param params the encoded parameters.
     *
     * @exception IOException on decoding errors
     */
    protected abstract void engineInit(byte[] params)
        ;

    /**
     * Imports the parameters from {@code params} and
     * decodes them according to the specified decoding format.
     * If {@code format} is null, the
     * primary decoding format for parameters is used. The primary decoding
     * format is ASN.1, if an ASN.1 specification for these parameters
     * exists.
     *
     * @param params the encoded parameters.
     *
     * @param format the name of the decoding format.
     *
     * @exception IOException on decoding errors
     */
    protected abstract void engineInit(byte[] params, string format)
        ;

    /**
     * Returns a (transparent) specification of this parameters
     * object.
     * {@code paramSpec} identifies the specification class in which
     * the parameters should be returned. It could, for example, be
     * {@code DSAParameterSpec.class}, to indicate that the
     * parameters should be returned in an instance of the
     * {@code DSAParameterSpec} class.
     *
     * @param <T> the type of the parameter specification to be returned
     *
     * @param paramSpec the specification class in which
     * the parameters should be returned.
     *
     * @return the parameter specification.
     *
     * @exception InvalidParameterSpecException if the requested parameter
     * specification is inappropriate for this parameter object.
     */
    // protected abstract
    //     <T extends AlgorithmParameterSpec>
    //     T engineGetParameterSpec(Class<T> paramSpec);

    /**
     * Returns the parameters in their primary encoding format.
     * The primary encoding format for parameters is ASN.1, if an ASN.1
     * specification for this type of parameters exists.
     *
     * @return the parameters encoded using their primary encoding format.
     *
     * @exception IOException on encoding errors.
     */
    protected abstract byte[] engineGetEncoded() ;

    /**
     * Returns the parameters encoded in the specified format.
     * If {@code format} is null, the
     * primary encoding format for parameters is used. The primary encoding
     * format is ASN.1, if an ASN.1 specification for these parameters
     * exists.
     *
     * @param format the name of the encoding format.
     *
     * @return the parameters encoded using the specified encoding scheme.
     *
     * @exception IOException on encoding errors.
     */
    protected abstract byte[] engineGetEncoded(string format);

    /**
     * Returns a formatted string describing the parameters.
     *
     * @return a formatted string describing the parameters.
     */
    protected abstract string engineToString();
}


/**
 * This class is used as an opaque representation of cryptographic parameters.
 *
 * <p>An {@code AlgorithmParameters} object for managing the parameters
 * for a particular algorithm can be obtained by
 * calling one of the {@code getInstance} factory methods
 * (static methods that return instances of a given class).
 *
 * <p>Once an {@code AlgorithmParameters} object is obtained, it must be
 * initialized via a call to {@code init}, using an appropriate parameter
 * specification or parameter encoding.
 *
 * <p>A transparent parameter specification is obtained from an
 * {@code AlgorithmParameters} object via a call to
 * {@code getParameterSpec}, and a byte encoding of the parameters is
 * obtained via a call to {@code getEncoded}.
 *
 * <p> Every implementation of the Java platform is required to support the
 * following standard {@code AlgorithmParameters} algorithms:
 * <ul>
 * <li>{@code AES}</li>
 * <li>{@code DES}</li>
 * <li>{@code DESede}</li>
 * <li>{@code DiffieHellman}</li>
 * <li>{@code DSA}</li>
 * </ul>
 * These algorithms are described in the <a href=
 * "{@docRoot}/../technotes/guides/security/StandardNames.html#AlgorithmParameters">
 * AlgorithmParameters section</a> of the
 * Java Cryptography Architecture Standard Algorithm Name Documentation.
 * Consult the release documentation for your implementation to see if any
 * other algorithms are supported.
 *
 * @author Jan Luehe
 *
 *
 * @see java.security.spec.AlgorithmParameterSpec
 * @see java.security.spec.DSAParameterSpec
 * @see KeyPairGenerator
 *
 * @since 1.2
 */

class AlgorithmParameters {

    // The provider
    private Provider provider;

    // The provider implementation (delegate)
    private AlgorithmParametersSpi paramSpi;

    // The algorithm
    private string algorithm;

    // Has this object been initialized?
    private bool initialized = false;

    /**
     * Creates an AlgorithmParameters object.
     *
     * @param paramSpi the delegate
     * @param provider the provider
     * @param algorithm the algorithm
     */
    protected this(AlgorithmParametersSpi paramSpi,
                                  Provider provider, string algorithm)
    {
        this.paramSpi = paramSpi;
        this.provider = provider;
        this.algorithm = algorithm;
    }

    /**
     * Returns the name of the algorithm associated with this parameter object.
     *
     * @return the algorithm name.
     */
    final string getAlgorithm() {
        return this.algorithm;
    }

    /**
     * Returns a parameter object for the specified algorithm.
     *
     * <p> This method traverses the list of registered security Providers,
     * starting with the most preferred Provider.
     * A new AlgorithmParameters object encapsulating the
     * AlgorithmParametersSpi implementation from the first
     * Provider that supports the specified algorithm is returned.
     *
     * <p> Note that the list of registered providers may be retrieved via
     * the {@link Security#getProviders() Security.getProviders()} method.
     *
     * <p> The returned parameter object must be initialized via a call to
     * {@code init}, using an appropriate parameter specification or
     * parameter encoding.
     *
     * @param algorithm the name of the algorithm requested.
     * See the AlgorithmParameters section in the <a href=
     * "{@docRoot}/../technotes/guides/security/StandardNames.html#AlgorithmParameters">
     * Java Cryptography Architecture Standard Algorithm Name Documentation</a>
     * for information about standard algorithm names.
     *
     * @return the new parameter object.
     *
     * @exception NoSuchAlgorithmException if no Provider supports an
     *          AlgorithmParametersSpi implementation for the
     *          specified algorithm.
     *
     * @see Provider
     */
    static AlgorithmParameters getInstance(string algorithm) {
        try {
            // Object[] objs = Security.getImpl(algorithm, "AlgorithmParameters",
            //                                  (string)null);
            // return new AlgorithmParameters((AlgorithmParametersSpi)objs[0],
            //                                (Provider)objs[1],
            //                                algorithm);
            implementationMissing();
            AlgorithmParametersSpi p;      
            return new AlgorithmParameters(p, null, algorithm);
        } catch(NoSuchProviderException e) {
            throw new NoSuchAlgorithmException(algorithm ~ " not found");
        }
    }

    /**
     * Returns a parameter object for the specified algorithm.
     *
     * <p> A new AlgorithmParameters object encapsulating the
     * AlgorithmParametersSpi implementation from the specified provider
     * is returned.  The specified provider must be registered
     * in the security provider list.
     *
     * <p> Note that the list of registered providers may be retrieved via
     * the {@link Security#getProviders() Security.getProviders()} method.
     *
     * <p>The returned parameter object must be initialized via a call to
     * {@code init}, using an appropriate parameter specification or
     * parameter encoding.
     *
     * @param algorithm the name of the algorithm requested.
     * See the AlgorithmParameters section in the <a href=
     * "{@docRoot}/../technotes/guides/security/StandardNames.html#AlgorithmParameters">
     * Java Cryptography Architecture Standard Algorithm Name Documentation</a>
     * for information about standard algorithm names.
     *
     * @param provider the name of the provider.
     *
     * @return the new parameter object.
     *
     * @exception NoSuchAlgorithmException if an AlgorithmParametersSpi
     *          implementation for the specified algorithm is not
     *          available from the specified provider.
     *
     * @exception NoSuchProviderException if the specified provider is not
     *          registered in the security provider list.
     *
     * @exception IllegalArgumentException if the provider name is null
     *          or empty.
     *
     * @see Provider
     */
    // static AlgorithmParameters getInstance(string algorithm,
    //                                               string provider)
    // {
    //     // if (provider.empty)
    //     //     throw new IllegalArgumentException("missing provider");
    //     // Object[] objs = Security.getImpl(algorithm, "AlgorithmParameters",
    //     //                                  provider);
    //     return new AlgorithmParameters((AlgorithmParametersSpi)objs[0],
    //                                    (Provider)objs[1],
    //                                    algorithm);
    // }

    /**
     * Returns a parameter object for the specified algorithm.
     *
     * <p> A new AlgorithmParameters object encapsulating the
     * AlgorithmParametersSpi implementation from the specified Provider
     * object is returned.  Note that the specified Provider object
     * does not have to be registered in the provider list.
     *
     * <p>The returned parameter object must be initialized via a call to
     * {@code init}, using an appropriate parameter specification or
     * parameter encoding.
     *
     * @param algorithm the name of the algorithm requested.
     * See the AlgorithmParameters section in the <a href=
     * "{@docRoot}/../technotes/guides/security/StandardNames.html#AlgorithmParameters">
     * Java Cryptography Architecture Standard Algorithm Name Documentation</a>
     * for information about standard algorithm names.
     *
     * @param provider the name of the provider.
     *
     * @return the new parameter object.
     *
     * @exception NoSuchAlgorithmException if an AlgorithmParameterGeneratorSpi
     *          implementation for the specified algorithm is not available
     *          from the specified Provider object.
     *
     * @exception IllegalArgumentException if the provider is null.
     *
     * @see Provider
     *
     * @since 1.4
     */
    // static AlgorithmParameters getInstance(string algorithm,
    //                                               Provider provider)
    // {
    //     if (provider is null)
    //         throw new IllegalArgumentException("missing provider");
    //     Object[] objs = Security.getImpl(algorithm, "AlgorithmParameters",
    //                                      provider);
    //     return new AlgorithmParameters((AlgorithmParametersSpi)objs[0],
    //                                    (Provider)objs[1],
    //                                    algorithm);
    // }

    /**
     * Returns the provider of this parameter object.
     *
     * @return the provider of this parameter object
     */
    final Provider getProvider() {
        return this.provider;
    }

    /**
     * Initializes this parameter object using the parameters
     * specified in {@code paramSpec}.
     *
     * @param paramSpec the parameter specification.
     *
     * @exception InvalidParameterSpecException if the given parameter
     * specification is inappropriate for the initialization of this parameter
     * object, or if this parameter object has already been initialized.
     */
    final void init(AlgorithmParameterSpec paramSpec)
    {
        if (this.initialized)
            throw new InvalidParameterSpecException("already initialized");
        paramSpi.engineInit(paramSpec);
        this.initialized = true;
    }

    /**
     * Imports the specified parameters and decodes them according to the
     * primary decoding format for parameters. The primary decoding
     * format for parameters is ASN.1, if an ASN.1 specification for this type
     * of parameters exists.
     *
     * @param params the encoded parameters.
     *
     * @exception IOException on decoding errors, or if this parameter object
     * has already been initialized.
     */
    final void init(byte[] params) {
        if (this.initialized)
            throw new IOException("already initialized");
        paramSpi.engineInit(params);
        this.initialized = true;
    }

    /**
     * Imports the parameters from {@code params} and decodes them
     * according to the specified decoding scheme.
     * If {@code format} is null, the
     * primary decoding format for parameters is used. The primary decoding
     * format is ASN.1, if an ASN.1 specification for these parameters
     * exists.
     *
     * @param params the encoded parameters.
     *
     * @param format the name of the decoding scheme.
     *
     * @exception IOException on decoding errors, or if this parameter object
     * has already been initialized.
     */
    final void init(byte[] params, string format) {
        if (this.initialized)
            throw new IOException("already initialized");
        paramSpi.engineInit(params, format);
        this.initialized = true;
    }

    /**
     * Returns a (transparent) specification of this parameter object.
     * {@code paramSpec} identifies the specification class in which
     * the parameters should be returned. It could, for example, be
     * {@code DSAParameterSpec.class}, to indicate that the
     * parameters should be returned in an instance of the
     * {@code DSAParameterSpec} class.
     *
     * @param <T> the type of the parameter specification to be returrned
     * @param paramSpec the specification class in which
     * the parameters should be returned.
     *
     * @return the parameter specification.
     *
     * @exception InvalidParameterSpecException if the requested parameter
     * specification is inappropriate for this parameter object, or if this
     * parameter object has not been initialized.
     */
    // final <T extends AlgorithmParameterSpec>
    //     T getParameterSpec(Class<T> paramSpec)
    //     throws InvalidParameterSpecException
    // {
    //     if (this.initialized == false) {
    //         throw new InvalidParameterSpecException("not initialized");
    //     }
    //     return paramSpi.engineGetParameterSpec(paramSpec);
    // }

    /**
     * Returns the parameters in their primary encoding format.
     * The primary encoding format for parameters is ASN.1, if an ASN.1
     * specification for this type of parameters exists.
     *
     * @return the parameters encoded using their primary encoding format.
     *
     * @exception IOException on encoding errors, or if this parameter object
     * has not been initialized.
     */
    final byte[] getEncoded()
    {
        if (this.initialized == false) {
            throw new IOException("not initialized");
        }
        return paramSpi.engineGetEncoded();
    }

    /**
     * Returns the parameters encoded in the specified scheme.
     * If {@code format} is null, the
     * primary encoding format for parameters is used. The primary encoding
     * format is ASN.1, if an ASN.1 specification for these parameters
     * exists.
     *
     * @param format the name of the encoding format.
     *
     * @return the parameters encoded using the specified encoding scheme.
     *
     * @exception IOException on encoding errors, or if this parameter object
     * has not been initialized.
     */
    final byte[] getEncoded(string format)
    {
        if (this.initialized == false) {
            throw new IOException("not initialized");
        }
        return paramSpi.engineGetEncoded(format);
    }

    /**
     * Returns a formatted string describing the parameters.
     *
     * @return a formatted string describing the parameters, or null if this
     * parameter object has not been initialized.
     */
    final string toString() {
        if (this.initialized == false) {
            return null;
        }
        return paramSpi.engineToString();
    }
}