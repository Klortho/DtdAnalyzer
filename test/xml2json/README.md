#XML-to-JSON samples directory

The DTDs and XML documents in this directory are for testing the feature of
auto-generating XSLTs that convert XML to JSON (see the GitHub wiki page for
documentation).

Run all of the tests with the bash script:

    ./make-samples.sh

Then, you can compare the newly generated JSON outputs with the reference outputs
to make sure everything worked:

    diff sample1.ref.json sample1.json
    diff sample2a.ref.json sample2a.json
    diff sample2b.ref.json sample2b.json
    diff sample3.ref.json sample3.json
    diff sample4.ref.json sample4.json
