/*
 * OptionHandler.java
 */

package gov.ncbi.pmc.dtdanalyzer;

import java.util.*;
import org.apache.commons.cli.*;

/**
 * Interface that defines one method, handleOption(opt), that needs to be
 * implemented by every application class.  It will return true if we successfully
 * handled the option; false otherwise.
 */
public interface OptionHandler {
    public boolean handleOption(Option opt);
}
