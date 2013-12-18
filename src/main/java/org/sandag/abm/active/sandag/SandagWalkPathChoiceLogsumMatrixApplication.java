package org.sandag.abm.active.sandag;

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.io.PrintWriter;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.text.DecimalFormat;
import java.util.*;

import org.apache.log4j.Logger;
import org.sandag.abm.active.AbstractPathChoiceLogsumMatrixApplication;
import org.sandag.abm.active.Network;
import org.sandag.abm.active.NodePair;
import org.sandag.abm.active.PathAlternativeList;
import org.sandag.abm.active.PathAlternativeListGenerationConfiguration;
import org.sandag.abm.application.SandagModelStructure;
import org.sandag.abm.ctramp.BikeLogsum;
import org.sandag.abm.ctramp.Person;
import org.sandag.abm.ctramp.Tour;

import com.pb.common.util.ResourceUtil;

public class SandagWalkPathChoiceLogsumMatrixApplication extends AbstractPathChoiceLogsumMatrixApplication<SandagBikeNode,SandagBikeEdge,SandagBikeTraversal>
{
	private static final Logger logger = Logger.getLogger(SandagWalkPathChoiceLogsumMatrixApplication.class);
	
	public static final String WALK_LOGSUM_SKIM_MGRA_MGRA_FILE_PROPERTY = "active.logsum.matrix.file.walk.mgra";
	public static final String WALK_LOGSUM_SKIM_MGRA_TAP_FILE_PROPERTY = "active.logsum.matrix.file.walk.mgratap";
	

    private PathAlternativeListGenerationConfiguration<SandagBikeNode,SandagBikeEdge,SandagBikeTraversal> configuration;
    
    public SandagWalkPathChoiceLogsumMatrixApplication(PathAlternativeListGenerationConfiguration<SandagBikeNode,SandagBikeEdge,SandagBikeTraversal> configuration)
    {
        super(configuration);
        this.configuration = configuration;
    }

    @Override
    protected double[] calculateMarketSegmentLogsums(PathAlternativeList<SandagBikeNode, SandagBikeEdge> alternativeList)
    {
        if ( alternativeList.getCount() > 1 ) {
            throw new UnsupportedOperationException("Walk logsums cannot be calculated for alternative lists containing multiple paths");
        }
        
        double utility = 0;
        SandagBikeNode parent = null;
        for (SandagBikeNode n : alternativeList.get(0)) {
            if ( parent != null ) {
                utility -= configuration.getNetwork().getEdge(parent,n).walkCost;
            }
            parent = n;
        }

        return new double[] {-utility};    
    }
    
    
    public static void main(String ... args) {
    	if (args.length == 0) {
    		logger.error( String.format("no properties file base name (without .properties extension) was specified as an argument.") );
    		return;
    	}
    	
    	logger.info("Building walk skims");
//    	String RESOURCE_BUNDLE_NAME = "sandag_abm_active_test";
        @SuppressWarnings("unchecked") //this is ok - the map will be String->String
        Map<String,String> propertyMap = (Map<String,String>) ResourceUtil.getResourceBundleAsHashMap (args[0]);
      
        SandagBikeNetworkFactory factory = new SandagBikeNetworkFactory(propertyMap);
        Network<SandagBikeNode, SandagBikeEdge, SandagBikeTraversal> network = factory.createNetwork();

        DecimalFormat formatter = new DecimalFormat("#.###");
        
        logger.info("Generating mgra->mgra walk skims");
        //mgra->mgra
        PathAlternativeListGenerationConfiguration<SandagBikeNode,SandagBikeEdge,SandagBikeTraversal> configuration =
        		new SandagWalkMgraMgraPathAlternativeListGenerationConfiguration(propertyMap,network);
        SandagWalkPathChoiceLogsumMatrixApplication application = new SandagWalkPathChoiceLogsumMatrixApplication(configuration); 
        Map<NodePair<SandagBikeNode>,double[]> logsums = application.calculateMarketSegmentLogsums();
        
        Path outputDirectory = Paths.get(configuration.getOutputDirectory()); 
        Path outputFile = outputDirectory.resolve(propertyMap.get(WALK_LOGSUM_SKIM_MGRA_MGRA_FILE_PROPERTY));
        
        try {
        	Files.createDirectories(outputDirectory);
        } catch (IOException e) {
        	throw new RuntimeException(e);
        }
            
        Map<Integer,Integer> originCentroids = configuration.getInverseOriginZonalCentroidIdMap();
        Map<Integer,Integer> destinationCentroids = configuration.getInverseDestinationZonalCentroidIdMap();

        try (PrintWriter writer = new PrintWriter(outputFile.toFile())) {
        	writer.println("i,j,value");
        	StringBuilder sb;
        	for (NodePair<SandagBikeNode> od : logsums.keySet()) {
        		sb = new StringBuilder();
        		sb.append(originCentroids.get(od.getFromNode().getId())).append(",");
        		sb.append(destinationCentroids.get(od.getToNode().getId())).append(",");
        		sb.append(formatter.format(logsums.get(od)[0])); //only one value here
        		writer.println(sb.toString());
        	}
        } catch (IOException e) {
        	throw new RuntimeException(e);
        }
        
        
        logger.info("Generating mgra->tap walk skims");
        //mgra->tap
        configuration = new SandagWalkMgraTapPathAlternativeListGenerationConfiguration(propertyMap,network);
        application = new SandagWalkPathChoiceLogsumMatrixApplication(configuration); 
        Map<NodePair<SandagBikeNode>,double[]> mgraTapLogsums = application.calculateMarketSegmentLogsums();
        
        //for later - get from the first configuration
        outputDirectory = Paths.get(configuration.getOutputDirectory()); 
        outputFile = outputDirectory.resolve(propertyMap.get(WALK_LOGSUM_SKIM_MGRA_TAP_FILE_PROPERTY));
        originCentroids = configuration.getInverseOriginZonalCentroidIdMap();
        destinationCentroids = configuration.getInverseDestinationZonalCentroidIdMap();
        
        //tap->mgra
        configuration = new SandagWalkTapMgraPathAlternativeListGenerationConfiguration(propertyMap,network);
        application = new SandagWalkPathChoiceLogsumMatrixApplication(configuration); 
        Map<NodePair<SandagBikeNode>,double[]> tapMgraLogsums = application.calculateMarketSegmentLogsums();
        
        //resolve if not a pair
        int initialSize = mgraTapLogsums.size() + tapMgraLogsums.size();
        
        for (NodePair<SandagBikeNode> mgraTapPair : mgraTapLogsums.keySet()) {
            NodePair<SandagBikeNode> tapMgraPair = new NodePair<SandagBikeNode>(mgraTapPair.getToNode(),mgraTapPair.getFromNode());
            if (!tapMgraLogsums.containsKey(tapMgraPair))
            	tapMgraLogsums.put(tapMgraPair,mgraTapLogsums.get(mgraTapPair));
        }
        
        for (NodePair<SandagBikeNode> tapMgraPair : tapMgraLogsums.keySet()) {
            NodePair<SandagBikeNode> mgraTapPair = new NodePair<SandagBikeNode>(tapMgraPair.getToNode(),tapMgraPair.getFromNode());
            if (!mgraTapLogsums.containsKey(mgraTapPair))
            	mgraTapLogsums.put(mgraTapPair,tapMgraLogsums.get(tapMgraPair));
        }
        int asymmPairCount = initialSize - (mgraTapLogsums.size() + tapMgraLogsums.size());
        if (asymmPairCount > 0)
        	logger.info("Boarding or alighting times defaulted to transpose for " + asymmPairCount + " mgra tap pairs with missing asymmetrical information");
        
        try {
        	Files.createDirectories(outputDirectory);
        } catch (IOException e) {
        	throw new RuntimeException(e);
        }

        try (PrintWriter writer = new PrintWriter(outputFile.toFile())) {
        	writer.println("mgra,tap,boarding,alighting");
        	StringBuilder sb;
        	for (NodePair<SandagBikeNode> od : mgraTapLogsums.keySet()) {
        		sb = new StringBuilder();
        		sb.append(originCentroids.get(od.getFromNode().getId())).append(",");
        		sb.append(destinationCentroids.get(od.getToNode().getId())).append(",");
        		sb.append(formatter.format(mgraTapLogsums.get(od)[0])).append(","); //only one value here
        		sb.append(formatter.format(tapMgraLogsums.get(new NodePair<>(od.getToNode(),od.getFromNode()))[0])); //only one value here
        		writer.println(sb.toString());
        	}
        } catch (IOException e) {
        	throw new RuntimeException(e);
        }
    }
}
