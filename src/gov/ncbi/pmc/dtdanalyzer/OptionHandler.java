/*
 * OptionHandler.java
 */

package gov.ncbi.pmc.dtdanalyzer;

import java.util.*;
import org.apache.commons.cli.*;

/**
 * Interface that defines one method, handleOption(opt), that needs to be
 * implemented by every application class.
 */
public interface OptionHandler {
    public void handleOption(Option opt);
}
