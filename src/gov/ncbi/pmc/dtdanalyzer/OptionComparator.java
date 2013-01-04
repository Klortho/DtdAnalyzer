/*
 * DtdAnalyzerOptComparator.java
 */

package gov.ncbi.pmc.dtdanalyzer;

import java.util.*;
import org.apache.commons.cli.*;

/**
 * Imposes an order on the output of options in the CLI usage message.
 * The argument to the constructor should be a String array of option names,
 * in the order that you want them to appear in the usage message.
 */
public class OptionComparator implements Comparator {

    // This is a list of long option names that defines the order.
    private String[] optList;

    public OptionComparator(String[] _optList) {
        optList = _optList;
    }

    public int compare(Object o1, Object o2) {
        //String opt1 = ((Option) o1).getOpt();
        //int opt1i = opt1 == null ? 1000 : order.indexOf(opt1);
        String opt1 = ((Option) o1).getLongOpt();
        String opt2 = ((Option) o2).getLongOpt();
        int opt1i = 1000;
        int opt2i = 1000;
        for (int i = 0; i < optList.length; ++i) {
            if (opt1.equals(optList[i])) opt1i = i;
            if (opt2.equals(optList[i])) opt2i = i;
        }
        
        return opt1i - opt2i;
    }
}
