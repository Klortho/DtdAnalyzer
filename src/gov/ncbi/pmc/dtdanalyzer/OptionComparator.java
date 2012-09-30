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
        String opt1 = ((Option) o1).getOpt();
        int opt1i = opt1 == null ? 1000 : order.indexOf(opt1);
        
        String opt2 = ((Option) o2).getOpt();
        int opt2i = opt2 == null ? 1000 : order.indexOf(opt2);
        
        return opt1i - opt2i;
    }
}
