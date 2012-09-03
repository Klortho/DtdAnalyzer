/*
 * DtdAnalyzerOptComparator.java
 */

package gov.ncbi.pmc.dtdanalyzer;

import java.util.*;
import org.apache.commons.cli.*;

/**
 * Imposes an order on the output of options in the CLI usage message.
 * The argument to the constructor should be a string consisting of the short option letters,
 * in the order that you want them to appear in the usage message.
 */
public class OptionComparator implements Comparator {

    private String order;

    public OptionComparator(String _order) {
        order = _order;
    }

    public int compare(Object o1, Object o2) {
        Option opt1 = (Option) o1;
        Option opt2 = (Option) o2;
        return order.indexOf(opt1.getOpt()) - order.indexOf(opt2.getOpt());
    }
}
